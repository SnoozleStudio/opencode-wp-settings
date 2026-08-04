---
name: to-tickets
description: Break any plan, spec, or conversation into small tracer-bullet tickets with declared blocking edges. Use when starting multi-step work, or to plan a session. Writes tickets as text in a local file by default; can use GitHub issues when the repo is linked.
---

# To-Tickets — Break Work into Slices

Turn a spec or plan into implementation tickets. Each ticket is a tracer bullet:
small enough to complete and verify in one focused pass.

## Ticket format (local file, `tickets/` or `docs/tickets/`)

```markdown
## {ID}. {Short imperative title}

- **Blocked by**: {IDs} or "none"   ← declared blocking edges (what must land first)
- **Blocks**: {IDs} or "none"
- **Files**: the files this ticket may touch
- **Acceptance**: how we know it's done (checkable, command or behavior)
```

## Rules

- Tickets are vertical slices where possible (a section end-to-end beats "CSS for all
  sections") — but honor dependencies (ACF fields before the template that reads them)
- Each ticket's verification maps to the project verification chain
- If tickets share a file, they're not parallel — serialize them (the DAG from the plan
  decides)
- Tracer-bullet size: completes in one session slice. "Add the hero section" ✓,
  "Implement the theme" ✗
- Order the file so the top is the next thing to do; mark done tickets `- [x]`

## GitHub mode

When the repo is linked and the user prefers GitHub: create issues via `gh issue create`
with the same fields (labels: e.g. `feature`, `bug`, `chore`). Link blocking by
referencing issue numbers in the body.

## Output

The ticket file path + a one-line execution order (what to do first, what can run in
parallel). Never start implementation on a ticket you haven't written down.
