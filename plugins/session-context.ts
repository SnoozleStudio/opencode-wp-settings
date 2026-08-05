import type { Plugin } from "@opencode-ai/plugin";
import { run } from "./lib/run";

const CACHE_TTL_MS = 30_000;

/**
 * Branch names are interpolated into the system prompt — strip anything that
 * is not a safe branch character (control chars, quotes, prompt-injection
 * text) before it gets there.
 */
const SAFE_BRANCH = /[^A-Za-z0-9_\-\/.]/g;

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
		const safeBranch = branch.replace(SAFE_BRANCH, "_");
		const status = (await run("git status --porcelain", directory)).stdout.trim();
		const changed = status === "" ? 0 : status.split("\n").length;
		cached = `Git state: branch ${safeBranch}, ${changed} uncommitted file(s).`;
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
