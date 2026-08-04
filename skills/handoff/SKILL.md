---
name: handoff
description: Compact the current session into a handoff document so another session or agent can continue the work. Use for "done for today", "continue this later", "hand this to someone else", context pressure, or before closing a session. Includes a checkpoint mode for mid-session quicksaves.
---

# Handoff — Continuity Across Sessions

Context is cheap to lose and expensive to rebuild. The handoff is the bridge.

## Save mode ("done for today")

Write `handoff.md` (or append to the session's running handoff) with:

1. **Goal** — what the work is, in the project's vocabulary (CONTEXT.md terms)
2. **State** — what's done, what's in progress, what's blocked (with the blocker)
3. **Files touched** — list with one-line notes
4. **Decisions** — choices made and why (link ADRs if they exist)
5. **Next steps** — ordered, with the verification chain each step must pass
6. **Open questions** — things the next session must ask the user
7. **Learnings** — anything for the self-evolving learnings log

Also record: current branch, uncommitted changes (`git status`), and any commands that
must be run before continuing (`npm install` after package.json changes, ACF sync).

## Checkpoint mode (mid-session quicksave)

Before risky operations (large refactors, multi-file rewrites, dependency upgrades):
- todo state + plan file snapshot
- `git diff --stat` summary
- the exact rollback command if things go sideways

## Resume mode ("continue this work")

1. Read the handoff doc
2. Re-read the files it names (post-compaction recovery: never trust memory)
3. Run `git status`/`git diff --stat` to reconcile with reality
4. Continue from "Next steps" — restate the goal in your first message

## Rules

- The handoff must let a fresh agent continue without asking the user anything that's
  already documented — the user's time is the budget
- Fail loud: if the handoff can't be completed (blocked work, unknown state), say so in
  the doc instead of papering over it
- Keep it tight: a good handoff is one page, not a novel
