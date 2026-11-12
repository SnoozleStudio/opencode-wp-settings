import type { Plugin } from "@opencode-ai/plugin";
import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { isGateCandidate, isGateSkip, resolveGateTarget } from "./lib/gate";
import { isWin32, run } from "./lib/run";

const GATE_CACHE_TTL_MS = 120_000;

const hasBuildScript = (dir: string): boolean => {
	try {
		const pkg = JSON.parse(readFileSync(join(dir, "package.json"), "utf8")) as {
			scripts?: Record<string, string>;
		};
		return typeof pkg.scripts?.build === "string";
	} catch {
		return false;
	}
};

const isGatedProject = (dir: string): boolean =>
	hasBuildScript(dir) &&
	(existsSync(join(dir, "phpcs.xml")) || existsSync(join(dir, "composer.json")));

/**
 * Proof-of-work gate: blocks `git push` / `git commit` until the project's
 * verification chain is green (build, format check, phpcs, phpstan). Mirrors
 * the cc-settings "gate" tier — a non-zero exit cannot be ignored.
 *
 * Skipped when:
 * - the project is not a WordPress theme/plugin (no build script + neither
 *   phpcs.xml nor composer.json)
 * - the command explicitly opts out (`--no-verify`, `HUSKY=0`, `SKIP_GATE=1` as
 *   standalone, unquoted tokens — mentions inside quotes never skip the gate)
 * - the command changes to a *different* working directory (`cd` /
 *   `Set-Location` / `pushd` / `Push-Location`) — the gate is scoped to the
 *   session directory; use `git -C <repo>` to gate another repo explicitly.
 *   A no-op `cd .` still gates the session repo.
 * - the chain passed within the cache window for the same target repo at the
 *   same HEAD and working-tree content (per-target — one repo's green cache
 *   never green-lights another)
 */
export const ProofOfWork = async ({ directory }: Parameters<Plugin>[0]) => {
	const gateCache = new Map<string, { at: number; state: string }>();

	/**
	 * Canonical chain commands (verbatim from docs/verification-chain.md — the
	 * consistency check enforces this). Composer bins are PHP proxies; POSIX
	 * runs `vendor/bin/x` directly, Windows cannot — cmd.exe splits the
	 * executable token at the `/` (`vendor/bin/phpcs` parses as the command
	 * `vendor` plus a switch) — so win32 rewrites them to the `.bat` shim at
	 * exec time.
	 */
	const runChain = async (cwd: string): Promise<{ ok: boolean; step: string; detail: string }> => {
		const steps: Array<[string, string]> = [
			["build", "npm run build"],
			["format:all:check", "npm run format:all:check"],
			["phpcs", "vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M"],
			["phpstan", "vendor/bin/phpstan analyse --no-progress --memory-limit=1G"],
		];
		const win32Shim = (cmd: string): string =>
			cmd.replace(/^vendor\/bin\/(\S+)/, "vendor\\bin\\$1.bat");
		for (const [name, cmd] of steps) {
			const out = await run(isWin32() ? win32Shim(cmd) : cmd, cwd);
			if (out.exitCode !== 0) {
				const raw = out.stdout.length > 0 ? out.stdout : out.stderr;
				return { ok: false, step: name, detail: raw.split("\n").slice(0, 30).join("\n") };
			}
		}
		return { ok: true, step: "", detail: "" };
	};

	const workingTreeState = async (dir: string): Promise<string> => {
		const hash = createHash("sha1");
		const head = (await run("git rev-parse HEAD", dir)).stdout;
		const status = (await run("git status --porcelain", dir)).stdout;
		const diff = (await run("git diff HEAD --binary", dir)).stdout;
		const untracked = (await run("git ls-files --others --exclude-standard -z", dir)).stdout;
		hash.update(head);
		hash.update(status);
		hash.update(diff);
		hash.update(untracked);
		for (const rel of untracked.split("\0").filter(Boolean)) {
			try {
				hash.update(readFileSync(join(dir, rel)));
			} catch {
				// A file removed between listing and hashing must not green-light the cache.
				hash.update(rel);
			}
		}
		return hash.digest("hex");
	};

	const gate = async (command: string): Promise<void> => {
		if (!isGateCandidate(command)) return;
		if (isGateSkip(command)) return;

		const resolved = resolveGateTarget(command, directory);
		if (resolved.skip) {
			console.warn(
				"proof-of-work: gate skipped — the command changes the working directory. " +
					"The gate is scoped to the session directory; use `git -C <repo>` to gate another repo."
			);
			return;
		}
		const target = resolved.target;

		if (!isGatedProject(target)) return;

		const state = await workingTreeState(target);
		const now = Date.now();
		const cached = gateCache.get(target);
		if (cached && now - cached.at < GATE_CACHE_TTL_MS && cached.state === state) return;

		const result = await runChain(target);
		if (!result.ok) {
			gateCache.delete(target);
			throw new Error(
				`proof-of-work: verification chain failed at "${result.step}". ` +
					`Run the checks and fix before committing/pushing.\n\n${result.detail}`
			);
		}
		gateCache.set(target, { at: now, state });
	};

	return {
		"tool.execute.before": async (
			input: { tool: string },
			output: { args: Record<string, unknown> }
		) => {
			if (input.tool !== "bash") return;
			await gate(String(output.args?.command ?? ""));
		},
	};
};
