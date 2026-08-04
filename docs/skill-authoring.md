# Skill Authoring — How to Write Skills for This Repo

Adapted from mattpocock's writing-great-skills + OpenCode's SKILL.md format. Skills are
the reusable discipline; commands wire them; agents execute them.

## Format (OpenCode)

- Location: `skills/<name>/SKILL.md` (global: `~/.config/opencode/skills/`; project:
  `.opencode/skills/`) — `SKILL.md` ALL CAPS
- Frontmatter: `name` (must match the directory name, lowercase + hyphens) and
  `description` (1–1024 chars). **The description is the selector** — the model sees
  only name + description until it loads the skill. Rich, trigger-phrase-dense
  descriptions are the difference between a skill that fires and one that doesn't
- Other frontmatter fields are ignored by OpenCode (kept for Claude compat: license,
  metadata)

## Structure (body)

1. **Goal** — what the skill does, in one sentence, domain vocabulary
2. **When to use / triggers** — explicit conditions
3. **Procedure** — numbered steps, ordered, with the quality bar at each step
4. **Reference** — link the relevant `docs/*.md` to load on-demand (keep SKILL.md lean)
5. **Rules** — the non-negotiables (never relax a check, never fake measurements, etc.)
6. **Output contract** — what the skill returns (findings table, verdict, files)

## Principles

- **Small and composable** — one skill, one job. A skill that does "everything" is a
  process framework nobody controls. Chain skills (fix → verify) instead of merging
- **User-invoked vs model-invoked** — workflows that need the user's input
  (grill-me, to-spec) are user-invoked via commands; disciplines the model can apply
  on its own (fix, verify, wp-security-audit) are model-invoked via description
- **Instructions over prose** — numbered steps and checklists beat paragraphs; agents
  follow numbered lists reliably
- **Quality bar at every step** — each step states what "done" looks like
- **Bias for boring** — no invented frameworks; the skill should encode the discipline,
  not a methodology

## Consistency rules

- Every skill that touches PHP runs the verification chain (build → format:all:check →
  phpcs) — state it
- Every skill that touches security references the escaping matrix, not prose
- Every skill that reviews uses file:line findings with severity
- Update `README.md` skill index when adding/removing skills
- Keep frontmatter descriptions fresh — they're the routing table

## References

- [OpenCode — Skills](https://opencode.ai/docs/skills) — the SKILL.md format and how skills load
- [mattpocock/skills](https://github.com/mattpocock/skills) — the writing discipline this repo adapts
- [cc-settings](https://github.com/darkroomengineering/cc-settings) — the config lineage this repo ports
- [Level 2 Guide](guide-pro.md) — skill authoring in context, with the wp-theme anatomy walkthrough
- Internal: [Documentation hub](README.md) — the skill inventory and the sync contract
