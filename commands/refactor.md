---
description: Refactor code to improve design without changing behavior. Small behavior-preserving steps with verification between each.
---

Refactor: $ARGUMENTS

Use the refactor skill: explore the module and its callers, state the target shape, then move in small behavior-preserving steps. Run the verification chain (build, format:all:check, phpcs, phpstan) after every step. If a step changes behavior, stop and flag it. Final diff gets a two-axis review. Report what moved, what stayed, what was flagged for later.
