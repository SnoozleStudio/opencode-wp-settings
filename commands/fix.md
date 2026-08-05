---
description: Debug and fix a bug or failure. Explores, reproduces, diagnoses, implements, verifies.
---

Fix the following bug: $ARGUMENTS

Follow the fix skill: spawn explore (neutral prompt), reproduce the failure, name the root cause in one sentence before editing, then implement with scope confined to the bug's files. Run the verification chain (npm run build, format:all:check, phpcs, phpstan) after every fix attempt. If 2 attempts fail, stop and present alternatives. Report: root cause, fix, files modified, verification result.
