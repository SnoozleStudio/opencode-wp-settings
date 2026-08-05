# Documentation Hub — Snoozle Studio OpenCode Settings

This is the map of the whole repository: every agent, skill, command, plugin, template,
and reference doc, what it does, and how they fit together. If a file in this repo
moves, changes, or appears, **this page and the guides are where it must be reflected**
(see [Documentation Contract](#documentation-contract)).

> **Reading paths**
>
> - I'm new to AI-assisted WordPress work → [Level 1 Guide](guide-beginners.md)
> - I'm a developer and want to extend the config itself → [Level 2 Guide](guide-pro.md)
> - I need a specific reference → use the indexes below

---

## Contents

1. [Repository map](#repository-map)
2. [Reference docs index](#reference-docs-index)
3. [Component inventory](#component-inventory)
   - [Agents (8)](#agents-8)
   - [Skills (26)](#skills-26)
   - [Commands (18)](#commands-18)
   - [Plugins (3)](#plugins-3)
   - [Templates (2)](#templates-2)
   - [Scripts & config](#scripts--config)
4. [Dependency map](#dependency-map)
5. [Documentation Contract](#documentation-contract)
6. [Verifying docs stay in sync](#verifying-docs-stay-in-sync)

---

## Repository map

```
~/.config/opencode/          ← THIS REPO (your global OpenCode config)
├── README.md                front door: value prop, install, quick start, links to the guides
├── LICENSE                  MIT license (incl. upstream attribution: cc-settings, mattpocock/skills)
├── AGENTS.md                portable coding standards + guardrails (bound every session)
├── opencode.json            permission allow/ask/deny matrix + MCP server config
├── tui.json                 TUI plugins (subagent statusline)
├── package.json / bun.lock  plugin runtime dependency (@opencode-ai/plugin)
├── agents/                  8 subagents (specialized workers OpenCode spawns)
├── skills/                  26 skills (reusable disciplines; auto-matched by description)
├── commands/                18 slash commands (user-invoked workflows)
├── plugins/                 3 hook plugins (proof-of-work gate, phpcs-watch, session-context)
├── docs/                    this hub + reference docs + the 2 guides
├── templates/               scaffolding sources (theme/, plugin/)
├── setup.ps1                validation + project scaffolding (PowerShell, Local-aware)
└── scaffold.cmd             shell-agnostic wrapper for setup.ps1 (cmd/Git Bash/PS)
```

---

## Reference docs index

Every reference doc, what it governs, and who loads it. Skills load their docs
**on demand** (see [Dependency map](#dependency-map)) — SKILL.md stays lean, the depth
lives here.

| Doc | Governs | Loaded by | Read it when |
|---|---|---|---|
| [wordpress-php-standards.md](wordpress-php-standards.md) | PHP syntax, naming, OOP, phpcs config, PHPStan config | `wp-plugin`, `wp-theme` | writing or reviewing any PHP |
| [wordpress-security.md](wordpress-security.md) | escaping matrix, sanitization, nonces, auth, SQLi, REST | `wp-security-audit`, `security-auditor` | anything touching input, output, or auth |
| [wordpress-plugin-architecture.md](wordpress-plugin-architecture.md) | plugin structure, lifecycle, REST, data | `wp-plugin` | building plugins |
| [wordpress-theme-architecture.md](wordpress-theme-architecture.md) | theme structure, template hierarchy, boot chain, enqueue | `wp-theme` | building themes |
| [frontend-stack.md](frontend-stack.md) | Vite, Tailwind v4, GSAP, Lenis, Tempus, Three.js, swup | `wp-theme` | writing or reviewing JS/CSS |
| [accessibility.md](accessibility.md) | WCAG 2.2 AA + Theme Review minimums | `wp-accessibility` | building or reviewing any UI |
| [performance.md](performance.md) | server-side + browser perf doctrine | `wp-performance` | optimizing or writing request-path code |
| [skill-authoring.md](skill-authoring.md) | how to write skills for this repo | anyone authoring skills | adding or editing a skill |
| [guide-beginners.md](guide-beginners.md) | Level 1: AI-driven workflows with example prompts | humans | starting out |
| [guide-pro.md](guide-pro.md) | Level 2: internals, authoring, orchestration | humans | extending the config |
| README.md (this file) | the map + the contract | everyone | orienting |

---

## Component inventory

> **Contract note:** each table is a *living document*. When a component changes, its
> table row, its file link, and the description in its own frontmatter change together.

### Agents (8)

Subagents in `agents/` are specialized workers OpenCode spawns with the
[Task tool](https://opencode.ai/docs/agents/). Read-only agents cannot edit by
permission; writers edit strictly within their briefing.

| Agent | File | Role | Read-only |
|---|---|---|---|
| Explore | [agents/explore.md](../agents/explore.md) | maps code, traces callers, answers "how does X work" | yes |
| Planner | [agents/planner.md](../agents/planner.md) | produces implementation plans, blast-radius analysis | yes |
| Implementer | [agents/implementer.md](../agents/implementer.md) | writes/edits production code per a complete briefing | no |
| Reviewer | [agents/reviewer.md](../agents/reviewer.md) | two-axis review: Standards + Spec | yes |
| Security Auditor | [agents/security-auditor.md](../agents/security-auditor.md) | full WP attack-surface review | yes |
| Tester | [agents/tester.md](../agents/tester.md) | runs/validates the verification chain | no |
| Scaffolder | [agents/scaffolder.md](../agents/scaffolder.md) | generates projects from `templates/`, new sections | no |
| Maestro | [agents/maestro.md](../agents/maestro.md) | orchestrates parallel subagent workstreams | no |

### Skills (26)

Skills in `skills/` are the reusable disciplines. OpenCode auto-matches them from the
frontmatter `description` — the description **is** the routing table. Category splits:

**WordPress**

| Skill | File | Loads docs | Trigger phrases |
|---|---|---|---|
| wp-plugin | [skills/wp-plugin/SKILL.md](../skills/wp-plugin/SKILL.md) | plugin-architecture, php-standards | "new plugin", CPT, settings page, REST route |
| wp-theme | [skills/wp-theme/SKILL.md](../skills/wp-theme/SKILL.md) | theme-architecture, frontend-stack | "new theme", page section, enqueue, GSAP/Lenis |
| wp-security-audit | [skills/wp-security-audit/SKILL.md](../skills/wp-security-audit/SKILL.md) | wordpress-security | "is this secure", XSS, SQLi, CSRF audit |
| wp-accessibility | [skills/wp-accessibility/SKILL.md](../skills/wp-accessibility/SKILL.md) | accessibility | WCAG, a11y, contrast, keyboard, aria |
| wp-performance | [skills/wp-performance/SKILL.md](../skills/wp-performance/SKILL.md) | performance | "slow site", web vitals, bundle size, rAF |
| wp-i18n | [skills/wp-i18n/SKILL.md](../skills/wp-i18n/SKILL.md) | — | translations, text domain, `esc_html_e` |

**Engineering**

| Skill | File | Loads docs | Trigger phrases |
|---|---|---|---|
| fix | [skills/fix/SKILL.md](../skills/fix/SKILL.md) | — | "fix", "broken", "bug", failing CI |
| diagnosing-bugs | [skills/diagnosing-bugs/SKILL.md](../skills/diagnosing-bugs/SKILL.md) | — | "hard to debug", intermittent, "works locally but not on server" |
| verify | [skills/verify/SKILL.md](../skills/verify/SKILL.md) | — | "double check", "prove it", high-stakes code |
| review | [skills/review/SKILL.md](../skills/review/SKILL.md) | — | review before commit/PR |
| refactor | [skills/refactor/SKILL.md](../skills/refactor/SKILL.md) | — | "refactor", "clean up", "reduce complexity" |
| tdd | [skills/tdd/SKILL.md](../skills/tdd/SKILL.md) | — | "TDD", "test-first", red-green-refactor |
| research | [skills/research/SKILL.md](../skills/research/SKILL.md) | — | "how does WP handle X", current best practice |
| domain-modeling | [skills/domain-modeling/SKILL.md](../skills/domain-modeling/SKILL.md) | — | jargon drifting, inconsistent naming |

**Productivity**

| Skill | File | Loads docs | Trigger phrases |
|---|---|---|---|
| grill-me | [skills/grill-me/SKILL.md](../skills/grill-me/SKILL.md) | — | "I want a booking form", ambiguous feature |
| grill-with-docs | [skills/grill-with-docs/SKILL.md](../skills/grill-with-docs/SKILL.md) | — | new project, fuzzy vocabulary + ADRs |
| to-spec | [skills/to-spec/SKILL.md](../skills/to-spec/SKILL.md) | — | feature fully discussed → written spec |
| to-tickets | [skills/to-tickets/SKILL.md](../skills/to-tickets/SKILL.md) | — | plan/spec → tracer-bullet tickets |
| handoff | [skills/handoff/SKILL.md](../skills/handoff/SKILL.md) | — | "done for today", session transfer |
| share-learning | [skills/share-learning/SKILL.md](../skills/share-learning/SKILL.md) | — | gotcha worth a learnings-log entry |

**Vendored (upstream, unedited)**

Copied from [greensock/gsap-skills](https://github.com/greensock/gsap-skills) (MIT) —
official GSAP API depth. Generic guidance (no WordPress/Vite/Lenis/Tempus): house
integration rules in `frontend-stack.md` override. Refresh with
`npx skills update -a opencode -g`; never edit in place.

| Skill | File | Trigger phrases |
|---|---|---|
| gsap-core | [skills/gsap-core/SKILL.md](../skills/gsap-core/SKILL.md) | GSAP tweens, easing, stagger, matchMedia |
| gsap-timeline | [skills/gsap-timeline/SKILL.md](../skills/gsap-timeline/SKILL.md) | timelines, sequencing, animation order |
| gsap-scrolltrigger | [skills/gsap-scrolltrigger/SKILL.md](../skills/gsap-scrolltrigger/SKILL.md) | scroll animation, parallax, pinning |
| gsap-plugins | [skills/gsap-plugins/SKILL.md](../skills/gsap-plugins/SKILL.md) | SplitText, Observer, Draggable, plugins |
| gsap-utils | [skills/gsap-utils/SKILL.md](../skills/gsap-utils/SKILL.md) | gsap.utils, clamp, snap, toArray |
| gsap-performance | [skills/gsap-performance/SKILL.md](../skills/gsap-performance/SKILL.md) | animation performance, jank, 60fps |

### Commands (18)

Slash commands in `commands/` are user-invoked workflows. Each is a markdown file whose
body is the prompt sent to the model; `$ARGUMENTS` is what you type after the slash.
See [guide-pro.md § Commands](guide-pro.md#commands-18) for authoring.

| Command | File | Invokes | Use when |
|---|---|---|---|
| `/fix` | [commands/fix.md](../commands/fix.md) | fix skill → explore + implementer | a bug or failure |
| `/build` | [commands/build.md](../commands/build.md) | grill-me (if ambiguous) → wp-plugin/wp-theme → maestro | a new feature or section |
| `/section` | [commands/section.md](../commands/section.md) | wp-theme skill | a new section in the current theme |
| `/check` | [commands/check.md](../commands/check.md) | verification chain directly | "is everything green?" |
| `/phpcs` | [commands/phpcs.md](../commands/phpcs.md) | phpcs directly | lint a file or the project |
| `/review` | [commands/review.md](../commands/review.md) | review skill → reviewer agent | before commit/PR |
| `/verify` | [commands/verify.md](../commands/verify.md) | verify skill (finder/adversary/referee) | adversarial proof of correctness |
| `/audit` | [commands/audit.md](../commands/audit.md) | explore + security-auditor + docs drift | whole-codebase audit |
| `/docs-check` | [commands/docs.md](../commands/docs.md) | inventory vs filesystem comparison | docs sync verification |
| `/refactor` | [commands/refactor.md](../commands/refactor.md) | refactor skill → reviewer | behavior-preserving restructure |
| `/grill` | [commands/grill.md](../commands/grill.md) | grill-me skill | align scope before starting |
| `/spec` | [commands/spec.md](../commands/spec.md) | to-spec skill | turn the conversation into a spec |
| `/tickets` | [commands/tickets.md](../commands/tickets.md) | to-tickets skill | break a plan into tickets |
| `/context` | [commands/context.md](../commands/context.md) | grill-with-docs / domain-modeling | build CONTEXT.md glossary + ADRs |
| `/handoff` | [commands/handoff.md](../commands/handoff.md) | handoff skill | save session state for later |
| `/theme` | [commands/theme.md](../commands/theme.md) | scaffolder agent + templates/theme | new theme project |
| `/plugin` | [commands/plugin.md](../commands/plugin.md) | scaffolder agent + templates/plugin | new plugin project |
| `/ship` | [commands/ship.md](../commands/ship.md) | verification chain + review → commit | full gate, review, commit |

### Plugins (3)

Hook plugins in `plugins/` run inside the OpenCode process and observe tool calls. They
are TS files built against `@opencode-ai/plugin` (see
[guide-pro.md § Plugins](guide-pro.md#plugins-3)).

| Plugin | File | Hooks | Behavior |
|---|---|---|---|
| Proof of work | [plugins/proof-of-work.ts](../plugins/proof-of-work.ts) | `tool.execute.before` (bash) | blocks `git push`/`git commit` until build + format + phpcs + phpstan are green (gated WP projects only) |
| phpcs-watch | [plugins/phpcs-watch.ts](../plugins/phpcs-watch.ts) | `tool.execute.after` (edit/write/apply_patch) | single-file phpcs pass after every `.php` edit; surfaces findings inline |
| Session context | [plugins/session-context.ts](../plugins/session-context.ts) | `experimental.chat.system.transform` | appends "Git state: branch, N uncommitted file(s)" to the system prompt |

### Templates (2)

Scaffolding sources consumed by the `scaffolder` agent and `setup.ps1`/`scaffold.cmd`.
Placeholders (`{slug}`, `{prefix}`, `{PREFIX}`, `{Prefix}`, `{text_domain}`, `{name}`,
`{description}`) are substituted at scaffold time. **The templates are the source of
truth — adapt, don't reinvent.**

| Template | Directory | Produces |
|---|---|---|
| Theme | [templates/theme](../templates/theme) | Vite + Tailwind v4 classic theme: style.css header, functions.php boot chain (utilities → nav-walker → configure → js-css), acf-json, .husky, phpstan.neon (ACF stubs) |
| Plugin | [templates/plugin](../templates/plugin) | classic plugin: main-file header, uninstall.php, admin/includes/public split, phpcs.xml, composer.json, phpstan.neon |

### Scripts & config

| File | Purpose |
|---|---|
| [setup.ps1](../setup.ps1) | `-Validate` repo structure/frontmatter; `-NewTheme`/`-NewPlugin` local dirs; `-Theme`/`-Plugin` into a Local site (walks up for `wp-load.php`, or `-Site <name>`); `-Install` npm+composer (Local PHP openssl workaround); `-Force`, `-DryRun` |
| [scaffold.cmd](../scaffold.cmd) | shell-agnostic wrapper (cmd/Git Bash/PowerShell) forwarding to setup.ps1 — the entry point from Local's site shell |
| [opencode.json](../opencode.json) | permission matrix (bash allowlist/ask/deny, secrets deny, `node -e` deny), MCP servers: context7 (enabled), chrome-devtools (disabled) |
| [tui.json](../tui.json) | TUI plugin `opencode-subagent-statusline` |
| [package.json](../package.json) / [bun.lock](../bun.lock) | runtime dependency `@opencode-ai/plugin` for `plugins/*.ts` |
| [.gitignore](../.gitignore) | repo hygiene (never commit `node_modules/`, `.env*`, local dumps) |

---

## Dependency map

How a request flows through the system:

```
You type                          OpenCode                        Specialist agents
─────────────────────────────    ───────────────────────────     ─────────────────────
"/fix the hero animation"  →  commands/fix.md (prompt)            explore  (maps code)
                              → skills/fix/SKILL.md (discipline)  implementer (edits)
                              → verification chain                tester (proves green)
                              → docs/wordpress-* (loaded on demand)
```

Command → skill/agent wiring:

```
/fix ──► fix ──► explore, implementer          /theme ──► scaffolder + templates/theme
/build ─► grill-me ─► wp-plugin|wp-theme ─► maestro (3+ pieces)
/section ─► wp-theme                           /plugin ─► scaffolder + templates/plugin
/review ─► review ─► reviewer                  /verify ─► verify (finder→adversary→referee)
/audit ─► explore + security-auditor + docs-drift
/ship ─► build → format → phpcs → phpstan → review → commit
```

Skill → reference doc wiring (loaded on demand, keeps SKILL.md lean):

```
wp-plugin ─► wordpress-plugin-architecture.md, wordpress-php-standards.md
wp-theme  ─► wordpress-theme-architecture.md, frontend-stack.md
wp-security-audit ─► wordpress-security.md
wp-accessibility  ─► accessibility.md
wp-performance    ─► performance.md
```

Plugin wiring (run inside the OpenCode process):

```
edit a .php file ──► phpcs-watch: single-file phpcs pass, inline findings
git push/commit  ──► proof-of-work: chain gate (skips non-WP projects, --no-verify, SKIP_GATE=1)
every session    ──► session-context: git state line appended to system prompt
```

---

## Documentation Contract

> **Every change to this repository must be synced with the documentation.** This is a
> binding rule for human and AI contributors alike (also recorded in
> [AGENTS.md](../AGENTS.md) — read it there in full).

### Mandatory sync targets

| You changed… | You must update… |
|---|---|
| An agent (`agents/`) | its `description` frontmatter + this hub's [Agents table](#agents-8) |
| A skill (`skills/`) | its `description` frontmatter (the routing table) + [Skills table](#skills-26) + skill-authoring.md if the format changed |
| A vendored skill (`gsap-*`) | never edit in place — bump via `npx skills update -a opencode -g`; inventory unchanged |
| A command (`commands/`) | its `description` + [Commands table](#commands-18) + any example walkthrough in the guides that uses it |
| A plugin (`plugins/`) | its docblock + [Plugins table](#plugins-3) + guide-pro § Plugins |
| A template (`templates/`) | the [Templates table](#templates-2) + guide-pro § Templates + the scaffolder agent if flow changed |
| `setup.ps1` / `scaffold.cmd` | the [Scripts table](#scripts--config) + README scaffolding section + guide-pro § Scaffolding |
| `opencode.json` / `tui.json` | README "What's inside" + guide-pro § Permissions/MCP |
| `README.md` "What's inside" | keep counts and file list truthful — they are verified by `/docs-check` |
| Anything user-facing | the [Level 1 guide](guide-beginners.md) (example prompts must stay accurate) |

### Adding a new component

A new skill, command, agent, or plugin is **not done** until it exists in:

1. Its own file with a rich `description` frontmatter
2. The relevant inventory table in this hub
3. The README "What's inside" listing (and skills/commands index)
4. A guide, if a human would ever invoke it (commands always; agents/skills when they
   change the workflow a human sees)

### Why this contract exists

- Agents and skills route on **descriptions** — a stale description means the model
  never fires the component (dead tooling that looks alive).
- The guides teach by example — a renamed command with an old example prompt is a
  lie in the docs.
- `/docs-check` and `/audit` pass 3 verify the contract; drift is a finding, not a
  nit.

---

## Verifying docs stay in sync

Two on-demand checks (read-only, both report drift without editing):

| Check | Command | Verifies |
|---|---|---|
| Docs sync | `/docs-check` | inventory tables vs filesystem (every file listed, every listed file exists), README counts, guide references |
| Full audit | `/audit` | pass 1 structure (explore), pass 2 security, pass 3 docs drift (AGENTS.md vs code, README vs reality, this hub vs filesystem) |

A green `/docs-check` is the pre-commit gate for documentation changes to this repo.
