---
name: grill-with-docs
description: Grilling session that also builds the project's domain model — sharpening terminology, updating CONTEXT.md, and recording architecture decisions as ADRs. Use for new projects, complex features, or when the team's vocabulary is drifting. Builds shared language that makes all future sessions cheaper.
---

# Grill-With-Docs — Alignment + Domain Model

Same as grill-me, but the outcome is written down: a shared language document
(`CONTEXT.md`) and architecture decision records (`docs/adr/`). Matt Pocock calls the
shared language the single most powerful technique in the skills library — jargon costs
tokens every session it goes undocumented.

## Before grilling

Check for existing docs: `CONTEXT.md`, `docs/adr/*.md`, project `AGENTS.md`. Load them —
if a term is already defined, don't redefine it.

## During grilling

Run the grill-me interview. As terms crystallize:

- **Domain terms**: when the user names something with precision ("the materialization
  cascade", "the scroll-docked header"), capture the term + one-line definition
- **Decisions**: when the user chooses between approaches, that's an ADR — record
  context, decision, consequences in `docs/adr/{NNNN}-{slug}.md` (Numbered, dated,
  supersedes links)

## Outputs

1. `CONTEXT.md` — glossary of project terms + one-paragraph domain summary. Terms:
   `**term** — definition.` one per line. It is read by every future session
   (explore, test, implement) so output stays aligned
2. `docs/adr/` — one file per decision, format:

```markdown
# {NNNN}. {Title}

Date: YYYY-MM-DD
Status: accepted

## Context
## Decision
## Consequences
```

3. The aligned implementation summary (goal, scope, non-goals)

## Rules

- Update CONTEXT.md/ADRs inline during the grilling — don't defer to "later"
- Terminology wins when code and docs conflict? No — flag the conflict; never silently
  rename in code
- ADRs are for decisions that are expensive to change (architecture, conventions), not
  trivial choices
