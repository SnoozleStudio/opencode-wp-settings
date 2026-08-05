import type { Plugin } from "@opencode-ai/plugin";
import { existsSync, readFileSync } from "node:fs";
import { isAbsolute, join } from "node:path";
import { run } from "./lib/run";

const GATE_CACHE_TTL_MS = 120_000;

/** `git commit` / `git push` — also the Windows `git.exe` form. */
const GIT_OP = /\bgit(\.exe)?\s+(push|commit)\b/i;

/**
 * Opt-out tokens only count as standalone, unquoted arguments. Quoted segments
 * are stripped first so a commit message that merely mentions `SKIP_GATE=1`
 * (or `--no-verify`) can never disable the gate.
 */
const SKIP_TOKEN = /(^|\s)(--no-verify|HUSKY=0|SKIP_GATE=1)(\s|$)/i;

/** `git -C <path>` — the gate can resolve and verify the target repo. */
const GIT_C = /\bgit(\.exe)?\s+-C\s*("[^"]+"|'[^']+'|[^\s;&|]+)/i;

/**
 * `cd` / `Set-Location` / `pushd` at a command boundary — the target repo
 * cannot be resolved reliably, so the gate skips with a warning.
 */
const DIR_CHANGE = /(^|[;&|]\s*)(cd|Set-Location|pushd)\s+/i;

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
 * - the project is not a WordPress theme/plugin (no build script + no phpcs.xml)
 * - the command explicitly opts out (`--no-verify`, `HUSKY=0`, `SKIP_GATE=1` as
 *   standalone, unquoted tokens — mentions inside quotes never skip the gate)
 * - the command changes the working directory (`cd` / `Set-Location` / `pushd`) —
 *   the gate is scoped to the session directory; use `git -C <repo>` to gate
 *   another repo explicitly
 * - the chain passed within the cache window for the same working tree state
 */
export const ProofOfWork = async ({ directory }: Parameters<Plugin>[0]) => {
	let lastGreen = 0;
	let lastState = "";

	const runChain = async (cwd: string): Promise<{ ok: boolean; step: string; detail: string }> => {
		const steps: Array<[string, string]> = [
			["build", "npm run build"],
			["format:all:check", "npm run format:all:check"],
			[
				"phpcs",
				"vendor\\bin\\phpcs --standard=phpcs.xml -d memory_limit=1024M",
			],
			["phpstan", "vendor\\bin\\phpstan analyse --no-progress --memory-limit=1G"],
		];
		for (const [name, cmd] of steps) {
			const out = await run(cmd, cwd);
			if (out.exitCode !== 0) {
				const raw = out.stdout.length > 0 ? out.stdout : out.stderr;
				return { ok: false, step: name, detail: raw.split("\n").slice(0, 30).join("\n") };
			}
		}
		return { ok: true, step: "", detail: "" };
	};

	const gate = async (command: string): Promise<void> => {
		if (!GIT_OP.test(command)) return;
		const unquoted = command.replace(/"[^"]*"|'[^']*'/g, "");
		if (SKIP_TOKEN.test(unquoted)) return;

		let target = directory;
		const cMatch = command.match(GIT_C);
		if (cMatch) {
			target = cMatch[2].replace(/^['"]|['"]$/g, "");
			target = isAbsolute(target) ? target : join(directory, target);
		} else if (DIR_CHANGE.test(command)) {
			console.warn(
				"proof-of-work: gate skipped — the command changes the working directory. " +
					"The gate is scoped to the session directory; use `git -C <repo>` to gate another repo."
			);
			return;
		}

		if (!isGatedProject(target)) return;

		const state = (await run("git status --porcelain", target)).stdout.trim();
		const now = Date.now();
		if (now - lastGreen < GATE_CACHE_TTL_MS && state === lastState) return;

		const result = await runChain(target);
		if (!result.ok) {
			lastGreen = 0;
			throw new Error(
				`proof-of-work: verification chain failed at "${result.step}". ` +
					`Run the checks and fix before committing/pushing.\n\n${result.detail}`
			);
		}
		lastGreen = now;
		lastState = state;
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
