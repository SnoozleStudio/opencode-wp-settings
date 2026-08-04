---
name: domain-modeling
description: Build and sharpen a project's domain model — challenge terms against the glossary, stress-test with edge-case scenarios, update CONTEXT.md and ADRs inline. Use when jargon is drifting, when files are named inconsistently, or after substantial feature work.
---

# Domain-Modeling — Keep the Language Sharp

The shared language decays silently: someone renames a concept, a term gains a second
meaning, code and docs drift apart. This skill repairs it.

## Audit

1. Read `CONTEXT.md` (if none, start from zero) + skim the codebase for repeated concepts
2. Compare: for every glossary term, does the code still use it? (grep the term — class
   names, function names, ACF field names, CSS classes)
3. Find drift: concepts in code with no term (grep a concept, several names come back),
   terms in CONTEXT.md no code references (dead vocabulary)

## Challenge & stress-test

For each disputed term:
- Edge-case scenario: "two pages both call themselves the {term} — is that the same
  thing?" If the answer is "actually different", split the term
- Naming consistency: files, functions, ACF fields, and hooks should all use the term
  (or its prefix) — list any that don't

## Update

- `CONTEXT.md`: add/split/remove terms with one-line definitions
- `docs/adr/`: a renamed concept or a split term is a decision worth recording
- Flag code that contradicts the model — rename only if the user approves (naming
  changes ripple; a cross-cutting rename is its own ticket)

## Rules

- Terminology wins over code, but you never unilaterally rename production code —
  propose the rename, name the blast radius, let the user decide
- Keep the glossary terse: one line per term, no essays
- This is a deepening tool, not a churn tool — run it after substantial work, not after
  every commit
