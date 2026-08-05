---
name: tdd
description: Test-driven development discipline adapted for WordPress: write a failing check first, watch it fail, implement, watch it pass, refactor. Use for "TDD", "test-first", "red-green-refactor". Lint and build are the fastest feedback loops when a PHPUnit harness isn't present.
---

# TDD — Red-Green-Refactor (WordPress-Adapted)

Enterprise WordPress ships with lint + build as the standard proof-of-work (PHPUnit/wp-env
is optional). The TDD loop adapts: the "test" is whatever fails first — a phpcs sniff, a
build error, or a PHPUnit assertion when the harness exists.

## Loop

1. **Red** — write the failing check first:
   - With a test harness: a PHPUnit test asserting the expected behavior
   - Without one: the failing phpcs case (e.g. unescaped output the escaping sniffs
     should catch), or a minimal repro script that asserts the wrong behavior
   - Watch it fail and confirm the failure is the assertion, not an error
2. **Green** — implement the minimum that passes the check. Nothing more
3. **Refactor** — clean up while green: naming, structure, deduplication. Re-run checks

## WordPress specifics

- The fastest red-green loop for template code: unescaped output → `esc_html()` —
  phpcs `WordPress.Security.EscapeOutput` catches it
- For logic (utilities, REST callbacks, option handling): PHPUnit + wp-env when present;
  otherwise a `php -l` + behavioral assertion script in `tests/`
- Never relax a check to go green — that's a contract change, not a fix

## Quality bar

- One vertical slice at a time (one section, one endpoint, one behavior)
- Checks are fast: full loop under a couple of minutes
- No tests that test the implementation (mock-heavy, whitespace-sensitive); assert
  behavior

## Verification chain after green

The canonical 4-step chain (build → format:all:check → phpcs → phpstan) — run it
in order, stopping at the first red (see `docs/verification-chain.md`).
