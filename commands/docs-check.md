---
description: Verify documentation sync — compare the docs/README.md inventory tables and README counts against the actual filesystem, and check that guide references resolve. Reports drift; read-only.
---

Check documentation sync: $ARGUMENTS

Read-only verification for THIS repo (~/.config/opencode). Verify:

1. **Inventory vs filesystem** — every agent/skill/command/plugin/template listed in
   docs/README.md must exist at the linked path, and every file in agents/, skills/
   (SKILL.md per directory), commands/, plugins/, templates/ must be listed. Counts
   must match.
2. **README "What's inside"** — the file tree and component counts in README.md must
   match reality (agents, skills, commands, plugins, docs).
3. **Guide references** — every command/skill/agent named in docs/guide-beginners.md
   and docs/guide-pro.md must exist; every internal link must resolve.
4. **Descriptions** — each component's frontmatter description is present (routing
   table rule).

Report each drift item as: inventory location (docs/README.md section + file:line)
vs actual filesystem path. Do not edit anything — the caller fixes, you find.

The mechanical subset (hub inventory vs filesystem, README/hub counts, internal
link resolution) is already scripted in scripts/docs-inventory.ps1 and runs in
CI. Focus this command on what the script cannot judge: description wording,
guide references by name, and drift reasoning. If the script reports findings,
fold them into your report rather than re-deriving them.
