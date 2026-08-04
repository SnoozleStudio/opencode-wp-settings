import type { Plugin } from "@opencode-ai/plugin";
import { existsSync } from "node:fs";
import { join } from "node:path";

const isWin32 = (): boolean => process.platform === "win32";
const wrap = (cmd: string): string => (isWin32() ? `cmd /c "${cmd}"` : cmd);

const MAX_REPORT_LINES = 24;

/**
 * phpcs-watch: after every edit to a `.php` file in a gated project, run a
 * single-file PHP_CodeSniffer pass and surface findings inline with the edit
 * result. The agent gets lint feedback at edit time instead of at commit time.
 *
 * Results land in `output.metadata.phpcs`; the tool title is prefixed with a
 * compact status so violations are visible at a glance.
 */
export const PhpcsWatch = async ({ directory, $ }: Parameters<Plugin>[0]) => {
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
		const out = await $.cwd(directory)
			.quiet()
			.nothrow()`${wrap(`${bin} --standard=phpcs.xml -d memory_limit=1024M ${filePath}`)}`;
		if (out.exitCode === 0) return { errors: 0, report: "" };
		const report = out.stdout.toString();
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
			const result = await lintFile(filePath);
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
