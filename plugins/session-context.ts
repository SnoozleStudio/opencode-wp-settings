import type { Plugin } from "@opencode-ai/plugin";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const CACHE_TTL_MS = 30_000;

const isWin32 = (): boolean => process.platform === "win32";
const execFileAsync = promisify(execFile);

/**
 * Run a command in the host shell and capture output. Uses child_process
 * instead of Bun's shell so behavior is identical across runtimes: output is
 * buffered (never echoed), the cwd is explicit, and non-zero exits are
 * returned instead of thrown.
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

/**
 * Session context: appends a compact git state line (branch + uncommitted
 * file count) to the system prompt so every session knows where it stands —
 * the OpenCode equivalent of a statusline. Cheap: one `git status
 * --porcelain`, cached 30s. No-op outside git repositories.
 */
export const SessionContext = async ({ directory }: Parameters<Plugin>[0]) => {
	let cached = "";
	let cachedAt = 0;

	const gitState = async (): Promise<string> => {
		const now = Date.now();
		if (now - cachedAt < CACHE_TTL_MS && cached !== "") return cached;
		const branch = (await run("git branch --show-current", directory)).stdout.trim();
		if (!branch) return "";
		const status = (await run("git status --porcelain", directory)).stdout.trim();
		const changed = status === "" ? 0 : status.split("\n").length;
		cached = `Git state: branch ${branch}, ${changed} uncommitted file(s).`;
		cachedAt = now;
		return cached;
	};

	return {
		"experimental.chat.system.transform": async (
			_input: { sessionID?: string },
			output: { system: string[] }
		) => {
			const state = await gitState();
			if (state !== "") output.system.push(state);
		},
	};
};
