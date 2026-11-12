import { homedir } from "node:os";
import { isAbsolute, join } from "node:path";

/**
 * `git commit` / `git push` — also the Windows `git.exe` form and the
 * `git -C <path> …` form (the option precedes the verb; without the optional
 * clause, `-C` in between would swallow the trigger and the gate would never
 * fire for the documented multi-repo path). Interposed git flags
 * (`--no-pager`, `-c key=value`, …) between `git` / `-C <path>` and the verb
 * are tolerated — otherwise `git --no-pager commit` returns early, ungated.
 * The flags fragment never matches `;`/`&`/`|` so chained commands cannot be
 * swallowed into a flag.
 */
const GIT_OP =
	/\b[gG][iI][tT](?:\.exe|\.EXE)?(\s+-C\s*("[^"]+"|'[^']+'|[^\s;&|]+))?(?:\s+-[^\s;&|]+(?:\s+[^\s;&|]+)?)*?\s+(push|commit)\b/;

/**
 * Opt-out tokens only count as standalone, unquoted arguments. Quoted segments
 * are stripped first so a commit message that merely mentions `SKIP_GATE=1`
 * (or `--no-verify`) can never disable the gate.
 */
const SKIP_TOKEN = /(^|\s)(--no-verify|HUSKY=0|SKIP_GATE=1)(\s|$)/i;

/** `git -C <path>` — case-sensitive: `-c key=value` is a different git option. */
const GIT_C =
	/\b[gG][iI][tT](?:\.exe|\.EXE)?(?:\s+-[^\s;&|]+(?:\s+[^\s;&|]+)?)*?\s+-C\s*("[^"]+"|'[^']+'|[^\s;&|]+)/;

/**
 * `git -c alias.p=push p` executes a push through an alias without ever
 * spelling the verb. Match the alias config and gate the resolved repo.
 */
const GIT_ALIAS =
	/\b[gG][iI][tT](?:\.exe|\.EXE)?(?:\s+-[^\s;&|]+(?:\s+[^\s;&|]+)?)*?\s+-c\s+alias\.[^\s;&|]+/;

/**
 * `cd` / `Set-Location` / `pushd` / `Push-Location` at a command boundary —
 * captures the target so a no-op `cd .` can still gate the session repo.
 */
const DIR_CHANGE = /(^|[;&|]\s*)(?:cd|Set-Location|pushd|Push-Location)\s+("[^"]+"|'[^']+'|[^\s;&|]+)/i;

const expandTarget = (target: string): string => {
	const value = target.replace(/^['"]|['"]$/g, "");
	if (value === "~") return homedir();
	if (value.startsWith("~/") || value.startsWith("~\\")) return join(homedir(), value.slice(2));
	return value
		.replace(/^\$HOME(?=$|[\\/])/, homedir())
		.replace(/^\$env:USERPROFILE(?=$|[\\/])/i, process.env.USERPROFILE ?? "");
};

const quotedRanges = (command: string): Array<[number, number]> => {
	const ranges: Array<[number, number]> = [];
	let start = -1;
	let quote = "";
	for (let i = 0; i < command.length; i++) {
		const char = command[i];
		if (start === -1) {
			if (char === '"' || char === "'") {
				start = i;
				quote = char;
			}
		} else if (char === quote) {
			ranges.push([start, i]);
			start = -1;
			quote = "";
		}
	}
	if (start !== -1) ranges.push([start, command.length]);
	return ranges;
};

const matchOutsideQuotes = (regex: RegExp, command: string): RegExpExecArray | null => {
	const ranges = quotedRanges(command);
	const global = new RegExp(regex.source, regex.flags.includes("g") ? regex.flags : `${regex.flags}g`);
	let match: RegExpExecArray | null;
	while ((match = global.exec(command))) {
		if (!ranges.some(([start, end]) => match!.index > start && match!.index < end)) {
			return match;
		}
		global.lastIndex = match.index + 1;
	}
	return null;
};

export const isGateCandidate = (command: string): boolean => {
	// Mask quoted segments so `rg "git commit"` does not fire the gate, but
	// keep a placeholder so `git -C "<path>" commit` still matches.
	const masked = command.replace(/"[^"]*"|'[^']*'/g, '"x"');
	return GIT_OP.test(masked) || GIT_ALIAS.test(command);
};

export const isGateSkip = (command: string): boolean =>
	SKIP_TOKEN.test(command.replace(/"[^"]*"|'[^']*'/g, ""));

export const resolveGateTarget = (
	command: string,
	dir: string
): { skip: boolean; target: string } => {
	const cMatch = matchOutsideQuotes(GIT_C, command);
	if (cMatch) {
		const expanded = expandTarget(cMatch[1]);
		return { skip: false, target: isAbsolute(expanded) ? expanded : join(dir, expanded) };
	}

	const dMatch = matchOutsideQuotes(DIR_CHANGE, command);
	if (dMatch) {
		const cdTarget = expandTarget(dMatch[2]);
		const resolved = isAbsolute(cdTarget) ? cdTarget : join(dir, cdTarget);
		const normalize = (p: string) => p.replace(/[\\/]+$/, "");
		if (normalize(resolved) !== normalize(dir)) {
			return { skip: true, target: dir };
		}
	}

	return { skip: false, target: dir };
};
