# Level 3 Guide — Tuning the Config (Advanced)

> For when the defaults are working and you want to tune: agent depth budgets, skill
> routing, plugin cache windows. Prereqs: read [Level 1 Guide](guide-beginners.md) and
> [Level 2 Guide](guide-pro.md). Changes to this repo must be synced with the
> [documentation hub](README.md) — see the Documentation Contract.

---

## 1. The step budget

Every subagent in `agents/` declares `steps: N` in its frontmatter — the maximum
number of tool calls the agent may make before it stops and returns. It is a hard
budget, not a hint: an agent that runs out returns what it has, partial work and all.

| Agent | Steps | Read-only | Typical use |
|---|---|---|---|
| Planner | 60 | yes | blast-radius analysis, implementation plans |
| Reviewer | 60 | yes | two-axis Standards + Spec review |
| Tester | 60 | no | runs/validates the verification chain |
| Explore | 80 | yes | mapping code, tracing callers |
| Scaffolder | 80 | no | generating projects from `templates/` |
| Security Auditor | 80 | yes | full attack-surface review |
| Implementer | 120 | no | writing/editing code per a briefing |
| Maestro | 200 | no | orchestrating parallel workstreams |

**What a step costs:** roughly one tool round-trip ≈ one unit of token spend. A
step budget is a token budget in disguise. Doubling `steps: 80` to `steps: 160` does
not double the quality — it doubles the ceiling on cost and on how long a runaway
task can burn before stopping.

## 2. When to raise (and lower) the budget

Raise when the workload is genuinely bigger per agent:

- **Explore 80 → 120**: very large codebases (10+ plugins, vendored blobs) where a
  single trace spans many files. Prefer `rg`/`grep` discovery first — reads with
  targeted offsets burn steps fastest.
- **Implementer 120 → 160**: multi-file features already mapped by a planner (the
  briefing gate should make this rare).
- **Maestro 200 → 300**: 5+ parallel workstreams with integration passes between
  phases.

Lower when the workload is small and focused — a single-file bug fix on a tiny
theme does not need a 120-step implementer:

- **Implementer 80**: one-file, one-function changes
- **Planner 40**: changes with a blast radius you already know

The defaults above are the tested values; change them in `agents/*.md`, and update
the hub [Agents table](README.md#agents-8) in the same change.

## 3. Out-of-steps fallback

When an agent hits its budget it stops mid-work and reports. Recovery options, in
order:

1. **Resume the same session** with the `task_id` from the previous call — the
   agent keeps its context and continues where it stopped. This is the cheapest
   recovery; nothing is lost.
2. **Re-brief a smaller chunk** — split the remaining work and send it as a fresh
   task with a tighter scope (files, not features).
3. **Plan the split** — if the work keeps exceeding budgets, the work itself is too
   big for one pass: run `/tickets` to break it into tracer bullets and run them
   sequentially.

Never silently extend an agent's budget mid-run to let it finish — that is how
runaway loops hide their cost. If two consecutive runs of the same shape run out,
change the *split*, not just the budget.

## 4. Tuning skill routing

The skill `description` frontmatter **is** the router — the model sees only name +
description until the skill loads. To change when a skill fires, change its
description, not any "routing" code (there is none).

- **Too eager** (fires on unrelated prompts): add explicit "not for…" cues
  (example: `review`, `verify`, `wp-security-audit` — see the priority table in
  [guide-pro § 7](guide-pro.md#7-skills--authoring)).
- **Never fires**: its trigger phrases don't match how the team talks. Add the
  actual phrases ("Use for 'is this secure', 'audit for XSS'…").
- **Description drift is dead tooling**: a skill whose description no longer matches
  its body either fires wrongly or never fires. `/docs-check` catches inventory
  drift, not wording drift — keep descriptions honest by hand.

Descriptions are 1–1024 chars (enforced by `setup.ps1 -Validate`).

## 5. Tuning plugin cache windows

The three hook plugins each cache so they don't burn I/O on every tool call:

| Plugin | Cache | Effect |
|---|---|---|
| proof-of-work | 120s per working-tree state | a green chain is not re-run if the tree is unchanged |
| session-context | 30s | git state line refreshed at most every 30s |
| phpcs-watch | 2s per file (clean only) | rapid re-edits of a clean file skip the inline lint |

Raise the proof-of-work cache for very slow chains (a heavy build + phpstan on a
big theme) — but remember the cache is **state-aware**: it compares `git status
--porcelain`, so a changed tree always re-runs the chain. Lower phpcs-watch's
cooldown to 0 if you want every edit linted (the cooldown never blocks the commit
gate, only the inline hint).

## 6. This repo is not gated

`proof-of-work` gates only projects with a `build` script **and** `phpcs.xml` or
`composer.json` (see [guide-pro § 4](guide-pro.md#4-plugins)). This config repo has
neither, so commits here skip the chain — the substitute discipline is the
documentation contract: `setup.ps1 -Validate`, `scripts/docs-inventory.ps1`, and
`scripts/verify-chain-consistency.ps1` before committing docs-affecting changes.

---

## References

- [Documentation hub](README.md) — inventory and the contract
- [Level 2 Guide](guide-pro.md) — agents, skills, plugins in depth
- [The verification chain](verification-chain.md) — what gated projects must pass
