import type { Plugin } from "@opencode-ai/plugin";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { isWin32, run } from "./lib/run";

const MAX_REPORT_LINES = 24;

/**
 * Rapid repeated edits of the same file only get one lint pass per window: a
 * clean file is not re-linted within LINT_COOLDOWN_MS (the inline hint is
 * suppressed, never the commit gate). A failed lint is always re-linted, so
 * the agent gets immediate "fixed" feedback after an edit.
 */
const LINT_COOLDOWN_MS = 2_000;

/**
 * Paths are interpolated into a `cmd.exe /c` string. Reject anything carrying
 * cmd metacharacters or quotes up front — a hostile file name must never
 * reach the shell. Spaces are rejected too (they would split the argument).
 */
const SAFE_FILE_PATH = /^[\w\-./\\]+$/;

/**
 * phpcs-watch: after every edit to a `.php` file in a gated project, run a
 * single-file PHP_CodeSniffer pass and surface findings inline with the edit
 * result. The agent gets lint feedback at edit time instead of at commit time.
 *
 * Results land in `output.metadata.phpcs`; the tool title is prefixed with a
 * compact status so violations are visible at a glance.
 */
export const PhpcsWatch = async ({ directory }: Parameters<Plugin>[0]) => {
	const lastLint = new Map<string, { at: number; clean: boolean }>();
	const phpcsBin = (): string | null => {
		const candidates = isWin32()
			? ["vendor\\bin\\phpcs.bat", "vendor\\bin\\phpcs"]
			: ["vendor/bin/phpcs"];
		for (const c of candidates) {
			if (existsSync(join(directory, c))) return c;
		}
		return null;
	};

	const gated = (): boolean =>
		existsSync(join(directory, "phpcs.xml")) && phpcsBin() !== null;

	const lintFile = async (filePath: string): Promise<{ errors: number; report: string }> => {
		const bin = phpcsBin();
		if (!bin) return { errors: 0, report: "" };
		const out = await run(
			`${bin} --standard=phpcs.xml -d memory_limit=1024M "${filePath}"`,
			directory
		);
		if (out.exitCode === 0) return { errors: 0, report: "" };
		const report = out.stdout;
		const errors = (report.match(/^\s*(\d+)\s*ERRORS?\b/im) ??
			report.match(/ERRORS?\s+(\d+)/im) ??
			[])[1] ?? "1";
		return {
			errors: Number.parseInt(String(errors), 10) || 1,
			report: report.split("\n").slice(0, MAX_REPORT_LINES).join("\n"),
		};
	};

	return {
		"tool.execute.after": async (
			input: { tool: string; args: Record<string, unknown> },
			output: { title: string; metadata: Record<string, unknown> }
		) => {
			if (!["edit", "write", "apply_patch"].includes(input.tool)) return;
			if (!gated()) return;
			const filePath = String(
				input.args?.filePath ?? input.args?.path ?? input.args?.file ?? ""
			);
			if (!filePath.endsWith(".php")) return;
			if (!SAFE_FILE_PATH.test(filePath)) {
				output.metadata.phpcs = {
					status: "skipped",
					reason: "unsafe path (rejected before reaching the shell)",
				};
				return;
			}
			const previous = lastLint.get(filePath);
			if (previous && previous.clean && Date.now() - previous.at < LINT_COOLDOWN_MS) return;
			const result = await lintFile(filePath);
			lastLint.set(filePath, { at: Date.now(), clean: result.errors === 0 });
			if (result.errors === 0) {
				output.metadata.phpcs = { status: "clean" };
				if (!output.title.startsWith("phpcs")) {
					output.title = `phpcs ✓ ${output.title}`;
				}
				return;
			}
			output.metadata.phpcs = { status: "fail", errors: result.errors, report: result.report };
			output.title = `phpcs ⚠ ${result.errors} error(s) — ${output.title}`;
		},
	};
};
