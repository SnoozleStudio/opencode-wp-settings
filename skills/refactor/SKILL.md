---
name: refactor
description: Restructure code to improve design without changing behavior. Use for "refactor", "clean up", "reorganize", "reduce complexity". Explore → plan → implement in small behavior-preserving steps → verify → review. Never refactors adjacent systems to the requested unit.
---

# Refactor — Behavior-Preserving Restructure

Refactoring changes shape, not behavior. Every step must keep the code green.

## Procedure

1. **Explore** — map the module and its callers (blast radius). What depends on this
   code, through what interfaces?
2. **Plan** — state the target shape: which seams exist, what moves where, what the
   before/after call graph looks like. The plan is the contract; a wrong plan means
   rollback
3. **Small steps** — one behavior-preserving step at a time: rename → extract → move →
   simplify. Run the verification chain after each step:
   `npm run build` → `npm run format:all:check` →
   `vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M` →
   `vendor/bin/phpstan analyse --no-progress --memory-limit=1G`
4. **No behavior change** — if a step changes output, ordering, or edge-case handling,
   it's not a refactor, it's a feature/bug — stop and flag it
5. **Review** — two-axis review on the final diff (Standards + Spec: spec here = "shape
   matches the plan, behavior unchanged")

## Scope rules

- Refactor the unit the user named — flag adjacent systems as out of scope, don't start
  them
- Never upgrade dependencies during a refactor
- When two contradictory patterns exist (Surface Conflicts rule): pick one, flag the
  other for follow-up — don't write code satisfying both

## Definition of done

Verification chain green, diff reviewable in one sitting, summary states: what moved,
what stayed, what was flagged for later.
