import type { Plugin } from "@opencode-ai/plugin";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const GATE_CACHE_TTL_MS = 120_000;

const isWin32 = (): boolean => process.platform === "win32";
const execFileAsync = promisify(execFile);

/**
 * Run a command in the host shell and capture output. Uses child_process
 * instead of Bun's shell so behavior is identical across runtimes: output is
 * buffered (never echoed), the cwd is explicit, and non-zero exits are
 * returned instead of thrown. On Windows the command runs through cmd.exe,
 * which resolves .cmd shims (npm, vendor\bin\phpcs.bat).
 */
const run = async (
	cmd: string,
	cwd: string
): Promise<{ stdout: string; stderr: string; exitCode: number }> => {
	try {
		const { stdout, stderr } = await execFileAsync(
			isWin32() ? "cmd.exe" : "/bin/sh",
			[isWin32() ? "/c" : "-c", cmd],
			{ cwd, encoding: "utf8" }
		);
		return { stdout, stderr, exitCode: 0 };
	} catch (error) {
		const err = error as { stdout?: string; stderr?: string; code?: number | string };
		return {
			stdout: typeof err.stdout === "string" ? err.stdout : "",
			stderr: typeof err.stderr === "string" ? err.stderr : "",
			exitCode: typeof err.code === "number" ? err.code : 1,
		};
	}
};

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
 * verification chain is green (build, format check, phpcs). Mirrors the
 * cc-settings "gate" tier — a non-zero exit cannot be ignored.
 *
 * Skipped when:
 * - the project is not a WordPress theme/plugin (no build script + no phpcs.xml)
 * - the command explicitly opts out (`--no-verify`, `HUSKY=0`, `SKIP_GATE=1`)
 * - the chain passed within the cache window for the same working tree state
 */
export const ProofOfWork = async ({ directory }: Parameters<Plugin>[0]) => {
	let lastGreen = 0;
	let lastState = "";

	const runChain = async (): Promise<{ ok: boolean; step: string; detail: string }> => {
		const steps: Array<[string, string]> = [
			["build", "npm run build"],
			["format:all:check", "npm run format:all:check"],
			[
				"phpcs",
				"vendor\\bin\\phpcs --standard=phpcs.xml -d memory_limit=1024M",
			],
		];
		for (const [name, cmd] of steps) {
			const out = await run(cmd, directory);
			if (out.exitCode !== 0) {
				const raw = out.stdout.length > 0 ? out.stdout : out.stderr;
				return { ok: false, step: name, detail: raw.split("\n").slice(0, 30).join("\n") };
			}
		}
		return { ok: true, step: "", detail: "" };
	};

	const gate = async (command: string): Promise<void> => {
		if (!/\bgit\s+(push|commit)\b/i.test(command)) return;
		if (/(--no-verify|HUSKY=0|SKIP_GATE=1)/i.test(command)) return;
		if (!isGatedProject(directory)) return;

		const state = (await run("git status --porcelain", directory)).stdout.trim();
		const now = Date.now();
		if (now - lastGreen < GATE_CACHE_TTL_MS && state === lastState) return;

		const result = await runChain();
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
