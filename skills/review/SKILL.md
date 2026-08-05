---
name: review
description: Two-axis code review of a diff since a fixed point — Standards (repo conventions, WordPress best practices, Fowler smell baseline) and Spec (faithful implementation of the originating ask). Use for "review my changes", "is this ready to commit/PR". Not for security deep-dives (use wp-security-audit) or adversarial logic proof (use verify). Delegates to the reviewer agent.
---

# Code Review

Delegates to the `reviewer` agent. Two axes, deliberately separated so neither pollutes
the other.

## Procedure

1. Determine the diff: `git diff` (unstaged), `git diff HEAD` (uncommitted), or
   `git diff <base>..<head>` for a branch
2. Spawn two review passes (or one agent running both axes with separation):

   **Standards axis** — against the repo's `AGENTS.md` + `phpcs.xml`:
   - PHP: escaping matrix, `wp_unslash` before sanitize, validation before sanitize,
     `$wpdb->prepare`, nonces + capabilities, i18n text domains, `array()`, Yoda, tabs,
     prefixes, one class per file
   - JS: ES modules, cleanup/teardown present, reduced-motion gates, no `var`
   - A11y: labels, aria, contrast, keyboard, focus
   - Fowler smell baseline: large functions, duplicated branches, leaky abstractions,
     speculative generality

   **Spec axis** — against the originating ask/spec:
   - Does the diff do what was asked? Missing edge cases, incomplete error paths,
     scope creep
3. Run `vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M` and report its
   findings verbatim — don't paraphrase them away
4. Verdict: APPROVE / APPROVE WITH NITS / REQUEST CHANGES, with numbered findings
   (file:line, severity, concrete fix)

## Rules

- Blocker findings mean the change does not ship; fix first, re-review the diff
- Never review your own work alone — the two-axis split is the minimum
- Small fixes get one pass; the axe is blunt for a 3-line diff — calibrate depth to
  change size (a bug-fix PR should review in under 2 minutes)
