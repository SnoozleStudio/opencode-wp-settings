# Docs Drift — Tickets

Semantic drift fixes from the full-sync audit (2026-09-28). Mechanical checks
were green throughout; these are wording/truthfulness fixes. Decision (b):
closed ticket files are kept as audit history — the hub retention rule now
says so instead of demanding deletion.

---

## [x] T62. Doc-drift fixes (1 major + 10 minor + 2 nits)

- **Blocked by**: none
- **Blocks**: T63
- **Files**: `docs/guide-beginners.md` (38 → 44 skills), `README.md` (workflow-lint
  bullet, standards-skill index), `docs/README.md` (Agents read-only nuance,
  `run()`/`isWin32()` imports, Tickets retention rule, repo-map macos row +
  ci.yml row, scaffold.cmd row, Tickets self-reference),
  `docs/guide-pro.md` (§4 essence elision note, §4 runner imports, Example C
  cache wording), `plugins/proof-of-work.ts` (gate-condition docblock)
- **Acceptance**: zero occurrences of `38 in skills`, `lastState`,
  `delete the file` in `docs/`; all hub/guide counts and import claims match
  the code they describe.
- **Recorded deviations**: none.

## [x] T63. Final verification gate

- **Blocked by**: T62
- **Blocks**: none
- **Files**: none (verification only)
- **Acceptance**: `-Validate`, `docs-inventory`, `verify-chain-consistency`
  green; stale-string grep clean; `git status` shows only intended files.
- **Recorded deviations**: none.
