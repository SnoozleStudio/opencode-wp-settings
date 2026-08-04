---
name: diagnosing-bugs
description: Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimize → hypothesize → instrument → fix → regression-test. Use for "hard to debug", "only happens sometimes", "works locally but not on the server", "slow page", "memory leak", "strange behavior".
---

# Diagnosing Bugs — The Loop

For bugs that resist direct fixes. The loop, in order — do not skip ahead.

## 1. Reproduce
Get it on screen deterministically. If it's intermittent, capture the conditions
(browser, viewport, reduced-motion state, logged-in user, ACF fields present).
No repro → you're guessing. A repro that takes 5 minutes is better than a hypothesis
that takes 20.

## 2. Minimize
Strip the case down: disable half the code paths (comments/toggles), find the minimal
input that triggers it. Bisect git history when a recent change is suspected —
`git bisect` or manual bisect across commits. Blame the affected file's history, not
the commit the bug report names.

## 3. Hypothesize
Name the cause in one sentence, with the mechanism: "X happens because Y, which leads
to Z." If the sentence needs "I think"/"maybe", you're not ready — instrument instead.

## 4. Instrument
Verify the hypothesis with evidence before editing:
- PHP: targeted logging (error_log with context), Query Monitor, step through the data
  flow
- JS/CSS: console, computed styles, forced layout measurement, screenshots — the
  `chrome-devtools` MCP when available
- WordPress: check what's actually enqueued/loaded on the page, which options/transients
  are hit, template file actually in use (`{$type}_template` filters)

## 5. Fix
Smallest fix that addresses the named mechanism — scope confined to the bug's files.

## 6. Regression-test
The repro passes; the verification chain is green
(`npm run build` → `npm run format:all:check` → phpcs). Record the cause + fix in the
project's self-evolving learnings log if non-obvious.

## Rules
- 2-attempt limit per hypothesis; after 2 failed fixes, stop and re-instrument
- Never "fix" by masking symptoms (adding a delay, hiding the element, swallowing the
  error) without naming what it's masking
- Visual bugs: if a CSS fix fails twice, propose 3 fundamentally different approaches
  and let the user pick
