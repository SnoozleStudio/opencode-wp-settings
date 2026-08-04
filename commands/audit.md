---
description: Whole-codebase audit — maintainability, correctness, security, and docs drift. Read-only; produces a findings report.
---

Audit: $ARGUMENTS

Read-only audit. Pass 1 (explore agent, neutral): whole-repo structural audit — 1k-line files, thin wrappers, leaked-logic boundaries, duplicate patterns, dead code. Pass 2 (security-auditor agent): WP attack surface — escaping matrix, SQLi, CSRF, capabilities, REST exposure, secrets in git history, options autoload. Pass 3: docs drift (AGENTS.md vs code, readme vs reality). Produce a findings report: numbered, with file:line, severity, CONFIRMED/PLAUSIBLE, and concrete fixes. Do not edit anything.
