import type { Plugin } from "@opencode-ai/plugin";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const isWin32 = (): boolean => process.platform === "win32";
const execFileAsync = promisify(execFile);

const MAX_REPORT_LINES = 24;

/**
 * Paths are interpolated into a `cmd.exe /c` string. Reject anything carrying
 * cmd metacharacters or quotes up front — a hostile file name must never
 * reach the shell. Spaces are rejected too (they would split the argument).
 */
const SAFE_FILE_PATH = /^[\w\-./\\]+$/;

/**
 * Run a command in the host shell and capture output. Uses child_process
 * instead of Bun's shell so behavior is identical across runtimes: output is
 * buffered (never echoed), the cwd is explicit, and non-zero exits are
 * returned instead of thrown. On Windows the command runs through cmd.exe,
 * which resolves .cmd shims (vendor\bin\phpcs.bat).
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
 * phpcs-watch: after every edit to a `.php` file in a gated project, run a
 * single-file PHP_CodeSniffer pass and surface findings inline with the edit
 * result. The agent gets lint feedback at edit time instead of at commit time.
 *
 * Results land in `output.metadata.phpcs`; the tool title is prefixed with a
 * compact status so violations are visible at a glance.
 */
export const PhpcsWatch = async ({ directory }: Parameters<Plugin>[0]) => {
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
