import type { Plugin } from "@opencode-ai/plugin";
import { existsSync } from "node:fs";
import { isAbsolute, join, relative, resolve } from "node:path";
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
 * Paths are interpolated into a `cmd.exe /c` string. Reject cmd
 * metacharacters and quotes up front; spaces are allowed because the path is
 * quoted. Drive letters are allowed so Windows absolute paths work.
 */
const SAFE_FILE_PATH = /^[A-Za-z0-9 _\-.:\\/]+$/;

const extractPatchPaths = (patchText: string): string[] => {
	const paths = new Set<string>();
	for (const pattern of [
		/^\*\*\* (?:Update|Add) File: (.+)$/gm,
		/^\*\*\* Move to: (.+)$/gm,
	]) {
		for (const match of patchText.matchAll(pattern)) {
			const value = match[1].trim();
			if (value) paths.add(value);
		}
	}
	return [...paths];
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

	const normalize = (raw: string): string | null => {
		if (raw === "" || !SAFE_FILE_PATH.test(raw)) return null;
		const absolute = isAbsolute(raw) ? resolve(raw) : resolve(directory, raw);
		const rel = relative(directory, absolute);
		if (rel === "" || rel.startsWith("..") || isAbsolute(rel)) return null;
		if (!rel.endsWith(".php")) return null;
		return rel;
	};

	const lintFile = async (filePath: string): Promise<{ errors: number; report: string }> => {
		const bin = phpcsBin();
		if (!bin) return { errors: 0, report: "" };
		const out = await run(
			`${bin} --standard=phpcs.xml -d memory_limit=1024M "${filePath}"`,
			directory
		);
		if (out.exitCode === 0) return { errors: 0, report: "" };
		const report = out.stdout.length > 0 ? out.stdout : out.stderr;
		const matched =
			report.match(/\bFOUND\s+(\d+)\s+ERRORS?\b/i) ?? report.match(/\b(\d+)\s+ERRORS?\b/i);
		const errors = matched ? Number.parseInt(matched[1], 10) || 1 : 1;
		return {
			errors,
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

			const rawPaths =
				input.tool === "apply_patch"
					? extractPatchPaths(String(input.args?.patchText ?? ""))
					: [String(input.args?.filePath ?? input.args?.path ?? input.args?.file ?? "")];
			const targets = [
				...new Set(
					rawPaths.map(normalize).filter((item): item is string => item !== null)
				),
			];
			if (targets.length === 0) return;

			let failure: { file: string; errors: number; report: string } | null = null;
			for (const file of targets) {
				const previous = lastLint.get(file);
				if (previous && previous.clean && Date.now() - previous.at < LINT_COOLDOWN_MS) continue;
				const result = await lintFile(file);
				lastLint.set(file, { at: Date.now(), clean: result.errors === 0 });
				if (result.errors > 0) {
					failure = { file, errors: result.errors, report: result.report };
					break;
				}
			}

			if (!failure) {
				output.metadata.phpcs = { status: "clean" };
				if (!output.title.startsWith("phpcs")) {
					output.title = `phpcs ✓ ${output.title}`;
				}
				return;
			}

			output.metadata.phpcs = {
				status: "fail",
				file: failure.file,
				errors: failure.errors,
				report: failure.report,
			};
			output.title = `phpcs ⚠ ${failure.errors} error(s) — ${output.title}`;
		},
	};
};
