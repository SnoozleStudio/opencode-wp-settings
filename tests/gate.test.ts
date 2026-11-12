import { describe, expect, test } from "bun:test";
import { homedir } from "node:os";
import { join } from "node:path";
import {
	isGateCandidate,
	isGateSkip,
	resolveGateTarget,
} from "../plugins/lib/gate";
import * as proofOfWorkPlugin from "../plugins/proof-of-work";

const dir = join(homedir(), "fake-project");

describe("plugin module shape", () => {
	test("exports only the plugin factory", () => {
		expect(Object.keys(proofOfWorkPlugin)).toEqual(["ProofOfWork"]);
	});
});

describe("gate trigger", () => {
	test("push/commit trigger", () => {
		expect(isGateCandidate("git commit -m done")).toBe(true);
		expect(isGateCandidate("git push origin main")).toBe(true);
		expect(isGateCandidate("git.exe commit")).toBe(true);
	});

	test("quoted mentions do not trigger", () => {
		expect(isGateCandidate('rg "git commit" src')).toBe(false);
	});

	test("alias triggers", () => {
		expect(isGateCandidate("git -c alias.p=push p")).toBe(true);
	});
});

describe("gate skip tokens", () => {
	test("standalone opt-out", () => {
		expect(isGateSkip("SKIP_GATE=1 git commit")).toBe(true);
		expect(isGateSkip("git commit --no-verify")).toBe(true);
	});

	test("quoted mention does not skip", () => {
		expect(isGateSkip('git commit -m "SKIP_GATE=1"')).toBe(false);
	});
});

describe("gate target", () => {
	test("defaults to the session directory", () => {
		expect(resolveGateTarget("git commit -m done", dir)).toEqual({
			skip: false,
			target: dir,
		});
	});

	test("-c config is not -C", () => {
		expect(resolveGateTarget("git -c user.name=test commit", dir)).toEqual({
			skip: false,
			target: dir,
		});
	});

	test("-C resolves the target", () => {
		expect(resolveGateTarget("git -C repo commit", dir)).toEqual({
			skip: false,
			target: join(dir, "repo"),
		});
		expect(resolveGateTarget('git -C "repo path" commit', dir)).toEqual({
			skip: false,
			target: join(dir, "repo path"),
		});
	});

	test("tilde expands", () => {
		expect(resolveGateTarget("git -C ~/repo commit", dir)).toEqual({
			skip: false,
			target: join(homedir(), "repo"),
		});
	});

	test("quoted commit message cannot retarget", () => {
		expect(resolveGateTarget('git commit -m "git -C /tmp"', dir)).toEqual({
			skip: false,
			target: dir,
		});
	});

	test("cd . still gates, cd elsewhere skips", () => {
		expect(resolveGateTarget("cd . && git commit", dir)).toEqual({
			skip: false,
			target: dir,
		});
		expect(resolveGateTarget("cd .. && git commit", dir).skip).toBe(true);
	});

	test("quoted cd message does not skip", () => {
		expect(resolveGateTarget('git commit -m "cd /tmp"', dir)).toEqual({
			skip: false,
			target: dir,
		});
	});
});
