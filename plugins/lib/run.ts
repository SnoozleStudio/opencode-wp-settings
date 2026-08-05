import { execFile } from "node:child_process";
import { promisify } from "node:util";

export const isWin32 = (): boolean => process.platform === "win32";

const execFileAsync = promisify(execFile);

export interface RunResult {
	stdout: string;
	stderr: string;
	exitCode: number;
}

/**
 * Run a command in the host shell and capture output. Uses child_process
 * instead of Bun's shell so behavior is identical across runtimes: output is
 * buffered (never echoed), the cwd is explicit, and non-zero exits are
 * returned instead of thrown. On Windows the command runs through cmd.exe,
 * which resolves .cmd shims (npm, vendor\bin\phpcs.bat).
 *
 * Shared by all hook plugins — change exec behavior here, not in the plugins.
 */
export const run = async (cmd: string, cwd: string): Promise<RunResult> => {
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
