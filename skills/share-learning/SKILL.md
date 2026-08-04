---
name: share-learning
description: Record a non-obvious bug, useful pattern, or edge case into the project's AGENTS.md self-evolving learnings log. Use when you hit a WordPress/library gotcha that another session or teammate's agent would benefit from knowing. Keeps knowledge in the repo, not in a forgotten chat.
---

# Share-Learning — Knowledge Routing

The learnings log is the debt you pay down for the next engineer (human or agent). One
line per entry, dated, factual.

## When to log

- A non-obvious bug and its root cause (e.g. "Vite `base` must be the absolute theme URL
  or font URLs 404")
- A WordPress gotcha that cost time (e.g. "wp_enqueue_script strategy defer + module
  rewrite must happen via script_loader_tag")
- A convention the team must follow (e.g. "all template output is escaped at echo time")
- A library integration pattern (Lenis + Tempus order, GSAP context cleanup)

## When NOT to log

- Personal workflow preferences → auto-memory
- Project state/deadlines → auto-memory (project)
- Anything already documented

## Format

Append under `## Self-Evolving Learnings` in the project's `AGENTS.md`:

```
- [2026-08-04] vite: manifest entry CSS must be enqueued with the hashed path or fonts 404
- [2026-08-04] wordpress: check_admin_referer dies with 403 — verify before the expensive work
```

Categories: wordpress, php, security, gsap, lenis, vite, tailwind, build, tooling.
Keep entries terse and factual — one line each.

## Rules

- If another project's agent would benefit, log it — the log is the team knowledge
  surface
- Prefer the log over prose: one line beats a paragraph for retrieval
- If the entry contradicts an existing one, flag the conflict rather than overwriting
  silently
