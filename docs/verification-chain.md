# The Verification Chain

The single source of truth for the WordPress proof-of-work chain. Every command,
skill, agent, and doc that references the chain points here — do not inline a copy
anywhere else.

## The chain

Run in order for theme/plugin projects; stop at the first red:

```text
npm run build                       # Vite production build (assets compile)
npm run format:all:check            # Prettier (JS/CSS/JSON) + Pint (PHP) dry-run
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

## Rules

1. **Run all four, in order** — build → format:all:check → phpcs → phpstan. An
   abbreviated chain (e.g. stopping at phpcs) is a red flag: phpstan catches type
   bugs phpcs can't see.
2. **Stop at the first red** — fix it, then re-run from the start. Never stack
   untested fixes.
3. **Never report green without running** — the exit code is the only evidence;
   "probably fine" is a lie.
4. **The `proof-of-work` plugin enforces it** — `git commit`/`git push` in a gated
   project are blocked until the chain is green (`--no-verify`/`SKIP_GATE=1` are the
   documented escape hatch, not the norm).

## When to run it

- After every unit of work (fixes, features, refactors)
- Before every commit or push in a WordPress theme/plugin project
- On demand: `/check` (chain only) or `/ship` (chain → review → commit)

The templates' `.husky/pre-commit` runs format:all:check + phpcs + phpstan as the
local gate; the chain above is the full picture.
