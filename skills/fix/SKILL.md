---
name: fix
description: Debug and fix bugs, errors, and failures — including merge conflicts and failing CI checks. Use for "fix", "broken", "not working", "bug", "error", "failing". Runs explore → reproduce → diagnose → implement → verify, with the 2-iteration limit and bug-fix scope confinement.
---

# Bug Fix Workflow

Bugs get fixed immediately — no "should I?" questions. But never stack untested fixes.

## Workflow

1. **Explore** — spawn `explore` to map the affected area (neutral prompts:
   "analyze the logic and report all findings", not "find the bug")
2. **Reproduce** — get the failure on screen. Run the failing command/flow, capture the
   error. No repro = no diagnosis
3. **Diagnose** — name the root cause in one sentence before touching code. Commits named
   in the bug report are hypotheses, not conclusions — blame the actually-affected file's
   history; regressions often rode in earlier on the same branch. If the sentence needs
   "I think"/"maybe", gather more signal (screenshots, computed styles, logs)
4. **Implement** — spawn `implementer` with a complete briefing (verbatim ask, file paths,
   scope). Scope confinement: only files directly related to the bug; no adjacent
   refactors; no dependency upgrades
5. **Verify** — run the verification chain: `npm run build` →
   `npm run format:all:check` → `vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M` →
   `vendor/bin/phpstan analyse --no-progress --memory-limit=1G`.
   Build after EVERY fix attempt, confirm green before moving on
6. **Learn** — non-obvious fix? Append a dated entry to the project's AGENTS.md
   self-evolving learnings log

## Rules

- **2-iteration limit**: after 2 failed attempts, stop, summarize, present 2-3
  alternatives, ask
- **Regression vs contract change**: a test/check failing after your change is either a
  regression (fix the code, never relax the check) or an intentional contract change
  (update implementation + assertion in the same diff, say which contract changed). When
  unsure, treat as regression
- **Failing PR CI**: `gh pr checks` is the source of truth; fix one actionable failure at
  a time; if unrelated to the PR and already fixed on main, merge main in instead
- **Merge conflicts**: resolve hunk by hunk by intent; regenerate lockfiles, never hand-
  edit; no broad refactors mid-conflict

## Output

Root cause (one sentence) / fix applied / files modified / verification commands + result
/ learning stored (if any). Fail loud if anything was skipped or mocked.
