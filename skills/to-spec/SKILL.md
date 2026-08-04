---
name: to-spec
description: Turn the current conversation into a written spec. No interview — synthesizes what was already discussed into a structured document. Use when a feature request has been fully discussed and needs a record before implementation.
---

# To-Spec — Synthesize the Conversation

You've aligned (or been discussing); now pin it down. No new questions unless a hole
blocks the spec — then ask ONE question, not an interview.

## Spec format

```markdown
# Feature: {Name}

## Goal
One sentence. In the project's vocabulary (from CONTEXT.md if present).

## Context
Why this exists; the conversation highlights that shaped it.

## Scope
- In: concrete deliverables
- Out: explicitly non-goals (be generous here — YAGNI)

## Behavior
- User story: "As a visitor on the services page, I can expand a service
  accordion so I can read its details"
- Acceptance criteria: checkable, numbered. Each maps to a verification step

## WordPress contract
- Templates/template-parts touched
- ACF fields/groups (names, types, location rules, option-page vs post meta)
- Hooks (custom actions/filters, timing)
- Enqueues (scripts/styles, strategies)
- i18n (strings, text domain)

## Verification
The commands + manual checks that prove the acceptance criteria.

## Risks
Anything uncertain (APIs to confirm, dependencies to add).
```

## Rules

- The spec is the contract for implementation — reviewers check the diff against it
  (Spec axis)
- If the conversation contradicts itself, surface the conflict and pick the most recent
  stated intent; note it
- Keep it under ~120 lines. A spec nobody can finish reading is not a spec
