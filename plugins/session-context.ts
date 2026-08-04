import type { Plugin } from "@opencode-ai/plugin";

const CACHE_TTL_MS = 30_000;

const isWin32 = (): boolean => process.platform === "win32";
const wrap = (cmd: string): string => (isWin32() ? `cmd /c "${cmd}"` : cmd);

/**
 * Session context: appends a compact git state line (branch + uncommitted
 * file count) to the system prompt so every session knows where it stands —
 * the OpenCode equivalent of a statusline. Cheap: one `git status
 * --porcelain`, cached 30s. No-op outside git repositories.
 */
export const SessionContext = async ({ directory, $ }: Parameters<Plugin>[0]) => {
	let cached = "";
	let cachedAt = 0;

	const gitState = async (): Promise<string> => {
		const now = Date.now();
		if (now - cachedAt < CACHE_TTL_MS && cached !== "") return cached;
		const branch = (
			await $.cwd(directory).quiet().nothrow()`${wrap("git branch --show-current 2>nul")}`
		)
			.stdout.toString()
			.trim();
		if (!branch) return "";
		const status = (
			await $.cwd(directory).quiet().nothrow()`${wrap("git status --porcelain")}`
		)
			.stdout.toString()
			.trim();
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
