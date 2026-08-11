# Level 2 Guide — Extending the Config (Pro Developers)

You know WordPress and you want to know how this machine works, and how to extend it.
This guide covers the internals of every layer, authoring examples for each component
type, and the discipline that keeps it all honest.

> Prereqs: read [Level 1 Guide](guide-beginners.md) and the
> [Documentation hub](README.md). Everything here is verified against the actual
> files in this repo — link, then read.

---

## Contents

1. [How the config loads](#1-how-the-config-loads)
2. [The permission matrix](#2-the-permission-matrix)
3. [MCP servers](#3-mcp-servers)
4. [Plugins](#4-plugins)
5. [Agents & the delegation decision](#5-agents--the-delegation-decision)
6. [Commands — authoring](#6-commands--authoring)
7. [Skills — authoring](#7-skills--authoring)
8. [Templates & the scaffolder](#8-templates--the-scaffolder)
9. [setup.ps1 & scaffold.cmd internals](#9-setupps1--scaffoldcmd-internals)
10. [The verification chain & proof-of-work gate](#10-the-verification-chain--proof-of-work-gate)
11. [The Documentation Contract in practice](#11-the-documentation-contract-in-practice)
12. [Advanced examples](#12-advanced-examples)
13. [References](#13-references)

---

## 1. How the config loads

This repo **is** your global OpenCode config. It lives at `~/.config/opencode/` and is
merged into every session, in every project:

```
~/.config/opencode/            ← global (this repo) — always loaded
project/opencode.json          ← project — merges OVER global
project/.opencode/             ← project-scoped agents/skills/commands — extend
```

- Global and project configs **merge**; project settings win on conflict. This repo is
  deliberately non-destructive to project setups.
- `AGENTS.md` is injected into the system prompt of every session — it is the portable
  standards doc. Any directory with its own `AGENTS.md` adds on top of the global one.
- `plugins/*.ts` are compiled and loaded at startup, keyed by
  `package.json` → `@opencode-ai/plugin` (the plugin SDK version this repo pins).
- `tui.json` loads the TUI plugin `opencode-subagent-statusline` (subagent status in
  the terminal UI).

**Security model in one line:** the AI may run many things without asking, may ask on
sensitive ones, and **cannot** touch secrets or destructive git operations — at the
permission level, not by prompt discipline.

---

## 2. The permission matrix

`opencode.json` → `permission`:

```jsonc
{
  "permission": {
    "bash": {
      "*": "ask", // default: ask before any command
      "npm run *": "allow", // build/format/dev: friction-free
      "git status*": "allow",
      "git checkout -- *": "deny", // destructive: denied, period
      "node -e *": "deny", // eval-style execution: denied
      "curl * | bash": "deny", // remote code execution: denied
      "cat ~/.ssh/*": "deny", // secrets: denied
    },
    "read": {
      "*": "allow",
      "~/.ssh/**": "deny",
      "~/.aws/**": "deny",
      "~/.npmrc": "deny",
      "…": "deny",
    },
    "edit": {
      "*": "allow",
      "~/.ssh/**": "deny",
      "~/.aws/**": "deny",
      "~/.npmrc": "deny",
      "…": "deny",
    },
    "webfetch": "allow",
    "skill": { "*": "allow" },
    "task": { "*": "allow" },
  },
}
```

What's allowed/asked/denied and why:

| Pattern                                                                                                                                                       | Verdict                                        | Rationale                                                                                         |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `npm run *`, `npm install` (bare), `npm info *`, `npx prettier*`, `npx tsc*`, `npx -y @upstash/context7-mcp*`, `npx skills add*`, `npx skills update*`        | allow                                          | the verification chain and tooling must never friction-block; anything beyond a bare install asks |
| `bun run *`                                                                                                                                                   | allow                                          | same, for the Bun runtime (`bunx *` removed — unscoped remote code execution)                     |
| `git status/diff/log/show/branch/blame/rev-parse/remote/stash/add/commit/push/pull/checkout <branch>`                                                         | allow                                          | read + normal workflow                                                                            |
| `git checkout -- *`, `git checkout .*`, `git restore *`, `git clean *`, `git reset --hard*`, `git branch -D *`, `git stash drop/clear`, `git push --force/-f` | **deny**                                       | irreversible history/work-tree damage                                                             |
| `composer install/dump-autoload/validate/show`                                                                                                                | allow                                          | toolchain                                                                                         |
| `composer require/update`                                                                                                                                     | ask                                            | dependency changes need your eyes                                                                 |
| `vendor/bin/phpcs/phpcbf/pint/phpstan`, `php -l`                                                                                                              | allow                                          | lint gates                                                                                        |
| `wp *`                                                                                                                                                        | ask                                            | WP-CLI mutates the database/site                                                                  |
| `gh pr/issue/run view*`, `gh repo view*`                                                                                                                      | allow; `gh pr create*`, `gh issue create*` ask | reads free, writes need consent                                                                   |
| `node -e/-p/--eval/--print`                                                                                                                                   | deny                                           | arbitrary code exec disguised as a flag                                                           |
| `curl` with pipes/`-o`/POST/PUT/DELETE                                                                                                                        | deny                                           | remote execution / silent writes                                                                  |
| `iwr/irm * \| iex`, `rm -rf /*`, `rm -rf ~*`, recursive Remove-Item, `rd /s`                                                                                  | deny                                           | ransomware-shaped commands                                                                        |
| `sudo *`                                                                                                                                                      | deny                                           | privilege boundary                                                                                |
| `cat/type/Get-Content ~/.ssh/* ~/.aws/* ~/.gnupg/* ~/.npmrc ~/.netrc ~/.docker/config.json ~/.kube/config`                                                    | deny                                           | secret material                                                                                   |
| `cat/type/Get-Content $HOME/* $env:USERPROFILE/* C:/Users/*/.ssh/*`                                                                                           | deny                                           | win32 case variants of the secret paths                                                           |
| `read`/`edit` of `~/.ssh/**`, `~/.aws/**`, `~/.gnupg/**`, `~/.npmrc`, `~/.netrc`, `~/.docker/config.json`, `~/.kube/config`                                   | deny                                           | secrets denied even on read                                                                       |

> Extending: add patterns by specificity. Broad `*` denies must come after the
> specific allows — the most specific pattern wins per command.

**Known residual — compound commands.** Patterns are whole-string globs: a command
starting with an allowed prefix matches that allow even when it chains more
(`npm run build && curl …` matches `npm run *`). This is a documented trade-off — the
chained tail patterns (`curl … | bash`, `-o` writes) only apply when they match the
whole string. Agents are instructed to keep compound commands minimal, and the
destructive denies still fire when the chain itself starts with a denied form. Do
not "fix" this with trailing-wildcard denies on every allow — they break legitimate
compound commands (`npm run build && npm run format:all:check`).

---

## 3. MCP servers

Two servers configured; both active (version-pinned so a breaking release can't
silently break the stack):

| Server          | Command                              | State   | Use                                                                                                                        |
| --------------- | ------------------------------------ | ------- | -------------------------------------------------------------------------------------------------------------------------- |
| Context7        | `npx -y @upstash/context7-mcp@4.0.0` | enabled | current library/framework docs on demand — **mandatory before assuming API knowledge** (AGENTS.md External Libraries rule) |
| chrome-devtools | `npx -y chrome-devtools-mcp@1.6.0`   | enabled | browser automation, a11y snapshots, profiling — auto-launches Chrome on the first page tool                                |

Pattern: Context7 for "does Vite 8 still call it `rolldownOptions`?" (it does — the
docs move, your training data doesn't); chrome-devtools for "inspect the computed
styles of the pinned header" when the Visual/Spatial Honesty rule applies.

---

## 4. Plugins

Plugins observe and intercept the tool-execution pipeline. The SDK surface used here:

- `tool.execute.before` — veto or gate a tool call (proof-of-work gate)
- `tool.execute.after` — enrich results (phpcs-watch)
- `experimental.chat.system.transform` — inject into the system prompt
  (session-context status line)

All three import the shared shell runner from `plugins/lib/run.ts` (`run()` +
`isWin32()`); keep exec-behavior changes there, not in the plugins.

### proof-of-work.ts — the commit gate

The heart of the "never ship red" rule:

```ts
// plugins/proof-of-work.ts (essence)
const gate = async (command: string): Promise<void> => {
  if (!/\bgit(\.exe)?\s+(push|commit)\b/i.test(command)) return; // only gate push/commit
  if (/(^|\s)(--no-verify|HUSKY=0|SKIP_GATE=1)(\s|$)/i.test(command)) return; // documented escapes
  const target = resolveTarget(command); // git -C <repo> honored; bare cd chains exempt
  if (!isGatedProject(target)) return; // needs build script + phpcs.xml/composer.json
  const result = await runChain(target); // build → format:all:check → phpcs → phpstan
  if (!result.ok)
    throw new Error(/* "proof-of-work: verification chain failed at …" */);
};
```

Behavioral details that matter:

- **Gating only applies to WordPress theme/plugin projects** — `isGatedProject` requires
  a `build` script in `package.json` AND `phpcs.xml` or `composer.json`. Plain repos
  are untouched.
- **Cache window:** a green chain is cached 120s **per target repo**, keyed by
  `git rev-parse HEAD` + `git status --porcelain`. Two repos — or two branches of
  the same repo — can never share a green cache; an unchanged tree at the same
  commit is the only thing that skips a re-run.
- **Escapes:** `--no-verify`, `HUSKY=0`, `SKIP_GATE=1` are explicit opt-outs — the
  escape hatch, not the norm (README guardrails). They only count as standalone,
  unquoted arguments — quoted segments are stripped first, so a commit message that
  merely mentions `SKIP_GATE=1` still gets gated.
- **Scope:** the gate verifies the repo the command targets. `git -C <repo> …` resolves
  and gates `<repo>`; commands that `cd` / `Set-Location` / `pushd` out of the session
  directory are exempt (target unresolvable) and skip with a warning — gate those repos
  with `git -C` explicitly.
- **Windows:** commands run through `cmd.exe /c`, which parses `/` as a switch
  separator — the canonical `vendor/bin/phpcs` form cannot execute there (it splits
  into the command `vendor` plus a switch). The gate rewrites `vendor/bin/<tool>` to
  `vendor\bin\<tool>.bat` at exec time on win32; POSIX runs the canonical form
  directly. Output is buffered, never echoed. `git.exe` is gated identically to `git`.
- **PHPStan step:** whole-project analysis, run after phpcs with
  `--no-progress --memory-limit=1G`; per-edit "phpstan-watch" is deliberately not
  wired up — partial-file analysis on a half-saved tree produces false positives.

### phpcs-watch.ts — lint at edit time

After every `edit`/`write`/`apply_patch` of a `.php` file in a gated project, runs a
single-file phpcs pass:

```ts
"tool.execute.after": async (input, output) => {
    if (!["edit", "write", "apply_patch"].includes(input.tool)) return;
    if (!gated()) return;                       // phpcs.xml + phpcs binary present
    const filePath = String(input.args?.filePath ?? input.args?.path ?? input.args?.file ?? "");
    if (!filePath.endsWith(".php")) return;
    const result = await lintFile(filePath);
    // clean  → output.metadata.phpcs = { status: "clean" }, title prefixed "phpcs ✓"
    // fail   → metadata gets { status, errors, report }, title prefixed "phpcs ⚠ N error(s)"
};
```

The point: **lint feedback arrives with the edit**, not at commit time. The agent
sees "phpcs ⚠ 3 error(s)" in the tool title and fixes before moving on.

**Cooldown:** a _clean_ lint of a file is cached 2s per file — rapid repeated edits of
the same file don't re-lint until the window passes. A _failed_ lint always re-lints,
so "fixed" feedback is immediate. The cooldown only suppresses the inline hint; the
commit gate (`proof-of-work`) always runs the full chain.

### session-context.ts — the statusline

Injects a git state line into the system prompt so every session knows where it
stands:

```ts
"experimental.chat.system.transform": async (_input, output) => {
    const state = await gitState();       // "Git state: branch main, 2 uncommitted file(s)."
    if (state !== "") output.system.push(state);
};
```

Cached 30s; no-op outside git repos.

### Writing your own plugin

Minimal shape (`plugins/my-plugin.ts`, then restart OpenCode):

```ts
import type { Plugin } from "@opencode-ai/plugin";

export const MyPlugin = async ({ directory }: Parameters<Plugin>[0]) => {
  return {
    "tool.execute.before": async (
      input: { tool: string },
      output: { args: Record<string, unknown> },
    ) => {
      // veto by throwing, or return undefined to pass
    },
  };
};
```

Every plugin ships: a docblock explaining intent, host-shell abstraction (the `run`
helper pattern — cmd.exe on win32, /bin/sh elsewhere), and explicit no-op conditions.

### Execution order & lifecycle

Plugins load in **filename order** (currently `phpcs-watch.ts` → `proof-of-work.ts` →
`session-context.ts`), but this is an implementation detail, **not an SDK guarantee** —
an `@opencode-ai/plugin` upgrade could change it. The three plugins are deliberately
independent (no cross-plugin dependencies, no shared mutable state), so order never
matters today.

There are no plugin startup/shutdown or project-detection lifecycle hooks. Every
plugin re-detects project state on **each** invocation:

- `proof-of-work.ts` calls `isGatedProject(target)` per `git commit`/`git push` —
  a newly scaffolded theme is gated correctly on first commit
- `phpcs-watch.ts` re-checks for `phpcs.xml` + the phpcs binary per edit — gating
  engages the moment the project has both
- `session-context.ts` refreshes git state on a 30s cache — always current

If a future plugin needs ordering or per-project initialization, request an
execution-order/lifecycle-hook feature from OpenCode — don't rely on filename order.

---

## 5. Agents & the delegation decision

Eight subagents, three flavors:

**Readers (denied edit/write by permission, not by instruction):**

| Agent            | depth    | Use for                                                    |
| ---------------- | -------- | ---------------------------------------------------------- |
| explore          | 80 steps | mapping, tracing, "how does X work" — neutral prompts only |
| planner          | 60 steps | DAGs, blast radius, WP-contract check, verification plans  |
| reviewer         | 60 steps | Standards + Spec axes, phpcs verbatim                      |
| security-auditor | 80 steps | full attack surface, proven findings (CONFIRMED/PLAUSIBLE) |

**Writers (edit within briefing only):**

| Agent       | depth     | Use for                                                         |
| ----------- | --------- | --------------------------------------------------------------- |
| implementer | 120 steps | production edits — bound by the **Briefing Gate** (below)       |
| scaffolder  | 80 steps  | greenfield from `templates/`, new sections in themes            |
| tester      | 60 steps  | running/proving the verification chain — never fabricates green |

**Orchestrator:**

| Agent   | depth     | Use for                                                  |
| ------- | --------- | -------------------------------------------------------- |
| maestro | 200 steps | 3+ parallel workstreams, phased execution, quality gates |

### The Briefing Gate (implementer)

An implementer must receive, before touching a file:

1. The original user ask, verbatim
2. Exact file paths + line ranges (from exploration)
3. The recommended approach (design decisions already made)
4. The verification command chain
5. Scope confinement: "only the files listed above"

Thin briefings create rework — the gate exists to make bad briefings impossible to
satisfy.

### The delegation decision table

| Situation                                                | Delegate to                                    |
| -------------------------------------------------------- | ---------------------------------------------- |
| "What does this code do?"                                | explore (or just ask — read-only conversation) |
| "How should we do X?" / multi-file change                | planner                                        |
| "Fix this bug"                                           | explore → implementer (via fix skill)          |
| "Build this feature"                                     | grill → implementer → tester → reviewer        |
| "Is this right?" (high-stakes)                           | verify skill (finder/adversary/referee)        |
| "Is this secure?"                                        | security-auditor                               |
| "Is this green?"                                         | tester                                         |
| "Review my diff"                                         | reviewer                                       |
| "New theme/plugin/section"                               | scaffolder                                     |
| "3+ independent pieces"                                  | maestro                                        |
| "Team vocabulary is drifting / project feels unfamiliar" | `/context` (glossary + ADR log)                |

---

## 6. Commands — authoring

A command is a markdown file in `commands/` with YAML frontmatter; the body is the
prompt. `$ARGUMENTS` is replaced by what you type after the slash.

```markdown
---
description: Run the full lint + format + build + static-analysis verification chain and report status.
---

Run the canonical verification chain ([verification-chain.md](verification-chain.md)) —
in order, stopping at the first red. Report each step's actual result (exit code +
first error line)…
```

Authoring rules distilled from the 18 existing commands:

1. **`description` is the menu** — it appears in the command picker. Imperative,
   outcome-stating, trigger-phrase rich ("Debug and fix a bug… Explores, reproduces,
   diagnoses, implements, verifies").
2. **Body = complete briefing** — the command must be enough on its own; it names the
   skill to use, the order of operations, the quality bar, and the report format.
3. **Point to the canonical verification chain** ([verification-chain.md](verification-chain.md))
   in every command that touches code — never inline a full copy.
4. **Fail-loud language** — "Never report green without running", "never commit a
   failing gate", "do not edit anything".
5. New command → update the [hub's command table](README.md#commands-18) + README
   counts + this guide if the workflow is user-facing. The `/docs-check` gate
   verifies the first two.

---

## 7. Skills — authoring

Full format in [docs/skill-authoring.md](skill-authoring.md). The essentials:

- Location `skills/<name>/SKILL.md`; frontmatter `name` **must match the directory**
  (setup.ps1 `-Validate` enforces this) and `description` (1–1024 chars).
- **The description is the router** — the model sees only name + description until it
  loads the body. Dense trigger phrases ("Use for 'fix', 'broken', 'not working'…")
  are what make a skill fire.
- Body structure: goal → triggers → numbered procedure with a quality bar per step →
  reference links to `docs/*.md` (loaded on demand — keep SKILL.md lean) → rules →
  output contract.
- Small and composable: chain skills (fix → verify) instead of merging.
- User-invoked skills (grill-me, to-spec) hang off commands; model-invoked
  disciplines (fix, verify, wp-security-audit) hang off description matching.

### Skill priority when multiple match

`review`, `verify`, and `wp-security-audit` overlap on "check this code". The model
routes on description density, so each description carries explicit "not for…" cues.
When in doubt, this is the intended split:

| User says                                                      | Best skill          | Why                                          | Not this                                                                       |
| -------------------------------------------------------------- | ------------------- | -------------------------------------------- | ------------------------------------------------------------------------------ |
| "review my changes / is this ready to commit"                  | `review`            | two-axis: Standards + Spec of a diff         | `verify` (no adversarial proof), `wp-security-audit` (no attack-surface proof) |
| "double check this logic / prove it / is the bug really fixed" | `verify`            | finder/adversary/referee correctness proof   | `review` (no adversary), `wp-security-audit` (not a logic proof)               |
| "is this secure / audit for XSS/SQLi/CSRF"                     | `wp-security-audit` | full attack surface, proven findings         | `review` (standards ≠ security), `verify` (logic ≠ vulnerabilities)            |
| "fix this bug" then "did it land?"                             | `fix` → `verify`    | fix disciplines the change; verify proves it | `review` alone (no fix procedure)                                              |

The `description` frontmatters of these three are the routing contract — if you change
one, change all three so the "not for…" cues stay mutually exclusive.

### Vendored upstream skills (gsap-*)

Six `gsap-*` skills are copied **unedited** from
[greensock/gsap-skills](https://github.com/greensock/gsap-skills) (MIT) — official API
depth for core/timeline/ScrollTrigger/plugins/utils/performance. Refresh with
`npx skills update -a opencode -g`; never edit them in place (updates would be
overwritten). Their guidance is generic — house integration rules (Lenis, not
ScrollSmoother; Tempus ticker; reduced-motion gate; manifest enqueue) live in
`docs/frontend-stack.md` and win over vendor guidance.

### Anatomy of a good skill (wp-theme as the reference)

```markdown
# WordPress Classic Theme — Enterprise Architecture

Classic themes (not block themes) that survive Theme Review. Load
`docs/wordpress-theme-architecture.md` and `docs/frontend-stack.md` for full references.
```

Then: canonical structure → non-negotiables → stack defaults ("do not invent
alternatives") → verification chain → scaffolding. Note the _contract trick_: it
loads the two reference docs by path, so the skill body stays ~100 lines while the
depth lives in `docs/`.

---

## 8. Templates & the scaffolder

`templates/` is the source of truth for greenfield work. The scaffolder agent and
`setup.ps1` both consume it; `setup.ps1` does plain token substitution, the agent
does semantic substitution (namespaces, class names, text domains).

### Token table (setup.ps1 `Resolve-Args`)

| Token                             | Becomes                            | Example (`-Slug my-plugin -Prefix myp_ -Name "My Plugin"`) |
| --------------------------------- | ---------------------------------- | ---------------------------------------------------------- |
| `{plugin_slug}` / `{plugin-slug}` | slug                               | `my-plugin`                                                |
| `{plugin_name}`                   | display name                       | `My Plugin`                                                |
| `{theme_slug}` / `{theme-slug}`   | slug (theme scaffolds)             | `my-theme`                                                 |
| `{theme_name}`                    | display name (theme scaffolds)     | `My Theme`                                                 |
| `{text_domain}`                   | slug (text domain must match slug) | `my-plugin`                                                |
| `{prefix}`                        | prefix, trailing `_` stripped      | `myp`                                                      |
| `{PREFIX}`                        | prefix upper                       | `MYP`                                                      |
| `{Prefix}`                        | prefix title-cased                 | `Myp`                                                      |
| `{description}`                   | placeholder description            | `Initial description.`                                     |

Prefix derivation rule: first 4 letters of the slug minus dashes + `_`
(`my-plugin` → `myp_`); explicit `-Prefix` overrides. Tokens are a
`Dictionary[string,string]` (PowerShell 5.1 hashtables are case-insensitive — a
known trap).

### Extending a template

- Theme boot chain is **load-order sensitive**: `functions.php` requires
  `configure/utilities.php` → `nav-walker.php` → `configure.php` → `js-css.php` →
  `acf.php`. New boot modules join in order; `nav-walker.php` is a fixed filename
  (the WPCS file-name sniff fires at line 0 — suppressed with `phpcs:disable`).
- New sections in a live theme: read one existing section first (house pattern),
  then PHP + ACF + escaped output, a `src/scripts/components/{name}.js` component
  (element guard → reduced-motion gate → Tempus → cleanup returned), wire into
  `main.js`, Tailwind tokens in `@theme`. That is exactly what the
  [scaffolder agent](../agents/scaffolder.md) encodes.
- The theme template ships one runnable house-pattern example —
  `src/scripts/components/hero.js` (element guard → reduced-motion gate →
  `gsap.context()` intro → `Tempus.add({ order: -1 })` parallax → cleanup
  returned), wired into `main.js` and driven by `data-hero` on `front-page.php`.
  Copy it when adding new components.
- ACF Pro is optional, not required: `front-page.php` guards `get_field()` with
  `function_exists()` and falls back to `bloginfo( 'name' )` when ACF is
  inactive; the save/load filters in `configure/acf.php` are inert without the
  plugin.
- The plugin template ships no compiled front-end assets: `public/css/public.css`
  and `public/js/public.js` are plain files enqueued as-is, and `npm run build`
  is a documented no-op (`exit 0`) so the proof-of-work gate's four-step chain
  runs for plugin projects too (the gate requires a `build` script).
- Both templates ship a `.husky/pre-commit` gate (format:all:check + phpcs +
  phpstan); the `prepare: husky` script installs the hooks on `npm install`.
- The plugin template's settings page is functional out of the box:
  `register_setting` + one `add_settings_section`/`add_settings_field` demo in
  `admin/class-{prefix}-admin.php` — extend it, don't remove the registration.

---

## 9. setup.ps1 & scaffold.cmd internals

### Parameters

| Parameter                              | Behavior                                                                                                                                                                                                                                                                          |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-Validate`                            | structure check: AGENTS.md/opencode.json present; every agent/skill/command has frontmatter + description; skill `name` matches directory; no plain-scalar description contains `: ` (colon+space — would break YAML parsing and kill the component's routing). Exit 1 on failure |
| `-NewTheme <dir>` / `-NewPlugin <dir>` | scaffold into an explicit local directory (no WP root needed)                                                                                                                                                                                                                     |
| `-Theme <slug>` / `-Plugin <slug>`     | scaffold into a WordPress root: walked-up root (site shell) or `-Site <name>`                                                                                                                                                                                                     |
| `-Site <name>` / `-SitesDir <dir>`     | resolve `{Local Sites}\<name>\app\public`; `-SitesDir` overrides the sites root                                                                                                                                                                                                   |
| `-Install`                             | `npm install` + `composer install` with the Local-PHP workaround                                                                                                                                                                                                                  |
| `-Force`                               | scaffold over an existing non-empty target (keeps extra files)                                                                                                                                                                                                                    |
| `-Slug` / `-Prefix` / `-Name`          | overrides; derived from the target leaf name otherwise                                                                                                                                                                                                                            |
| `-DryRun`                              | render every file in memory, validate (no stray `{tokens}`, no reserved Windows names, JSON/XML parses), print what would be written — change nothing. A dry run that prints "would write" for a broken scaffold is a lie                                                         |

### Root resolution & the Local workaround

- `Resolve-WpRoot` walks up from cwd until `wp-load.php` — that's how the site shell
  (which starts at `<site>\app\public`) needs no `-Site` argument.
- `Resolve-LocalSiteRoot` requires `app\public` containing `wp-load.php` and lists
  available sites when a name misses.
- **Local's bundled PHP ships with openssl/mbstring disabled** in its `php.ini`, which
  breaks `composer install` (TLS). `Invoke-ProjectInstall` detects Local's PHP by
  matching `lightning-services` in the path, writes a temp `php.ini` with
  `extension=openssl` + `extension=mbstring`, points `$env:PHPRC` at it, installs,
  and restores the environment (including deleting the temp ini) in `finally`.
  System PHP installs are used untouched.
- `scaffold.cmd` is the shell-agnostic door: Local's Windows site shell opens
  **cmd.exe by default**, where `&`-call syntax and `$HOME` don't exist. The wrapper
  is a `@echo off` stub that forwards `%*` to
  `powershell -NoProfile -ExecutionPolicy Bypass -File …\setup.ps1` — works from
  cmd, Git Bash, and PowerShell alike.
- Encoding discipline: files are written UTF-8 **without BOM**
  (`[System.IO.File]::WriteAllText` + `UTF8Encoding($false)`) — PowerShell 5.1's
  `Set-Content -Encoding UTF8` writes a BOM that breaks things; `Get-Content`
  defaults to ANSI, so .ps1 and template files stay ASCII-only.

---

## 10. The verification chain & proof-of-work gate

The chain is defined once in [verification-chain.md](verification-chain.md) — build →
format:all:check → phpcs → phpstan, in order, stop at first red. What each step does:

- **build** — Vite production build (the `dist/` output your PHP enqueues via the
  manifest)
- **format:all:check** — Prettier (JS/CSS/JSON) + Pint (PHP) dry-run
- **phpcs** — WPCS 3.0 (WordPress-Extra + WordPress-Docs + PHPCompatibility,
  `testVersion 8.2-`)
- **phpstan** — level 8 with `szepeviktor/phpstan-wordpress` (WP globals/functions
  stubs); the theme neon additionally scans `php-stubs/acf-pro-stubs`

The gate plugin enforces it (see [§4 Plugins](#4-plugins)): `git push`/`git commit`
in a gated project run the chain first, cached 120s per tree state. Known PHPCS
landmines documented in the repo: never `ref="Universal"` wholesale (mutually
exclusive sniffs pair), PHPCompatibilityWP is gone in phpcompatibility 9.x (use
`PHPCompatibility`), and the Vite hash-as-version enqueue needs a
`phpcs:disable`/`enable` comment rather than a fake `$ver`.

`/check` runs the chain on demand; `/ship` runs chain → two-axis review → commit.
`tester` is the agent that proves "green" honestly — and the only thing that may
claim it.

This repo runs its own server-side backstop for the same discipline:
`.github/workflows/ci.yml` validates JSON well-formedness, repo structure and
frontmatter (`setup.ps1 -Validate`), the docs inventory
(`scripts/docs-inventory.ps1` — the mechanical subset of `/docs-check`),
chain consistency (`scripts/verify-chain-consistency.ps1` — the doc's four
commands vs the gate's hardcoded steps), lockfile integrity
(`bun install --frozen-lockfile --dry-run`), and scaffold dry runs, on every
push to `main` and every pull request. The README badge is the visible proof;
the semantic gate stays local in `proof-of-work.ts`.

`/docs-check` remains the semantic companion to the script: description wording,
guide references by name, drift reasoning — things a deterministic script cannot
judge.

---

## 11. The Documentation Contract in practice

The contract (also in [AGENTS.md](../AGENTS.md) and the
[hub](README.md#documentation-contract)): **every change to this repo updates the
documentation in the same change.** A checklist that makes it mechanical:

```
[ ] component's own description/frontmatter updated   (it's the routing table)
[ ] docs/README.md inventory row updated              (it's the map)
[ ] README.md "What's inside" + indexes updated       (counts must be truthful)
[ ] guides updated if a human-visible workflow changed (examples must not lie)
[ ] /docs-check green                                  (drift = finding, not nit)
```

Why it's enforced at the _documentation layer_ and not in a commit plugin: the
routing table (descriptions) and the map (inventory) are cheap to verify on demand,
and the human-in-the-loop review catches what automation can't. The hard gate stays
reserved for code correctness (proof-of-work), which is the thing that breaks
production.

---

## 12. Advanced examples

### Example A — parallel feature work with maestro

```
You:  "build three sections for the landing page: hero, services, testimonials"

1. grill-me aligns scope (fields, data, behavior)
2. maestro plans the DAG: three independent slices, no shared files
3. fan out three implementers with complete briefings
4. tester verifies each slice as it lands (never integrate a red slice)
5. reviewer runs Standards + Spec on the integrated diff
6. report: per-slice status + what needs browser validation
```

The rules that make it safe: parallel slices never touch the same files; every
briefing is complete; the 2-iteration limit applies per slice; the maestro cannot
approve its own work.

### Example B — a custom subagent

Create `agents/glossary-writer.md` (or extend `agents/planner.md` — prefer the
Laziness Ladder: reuse before re-create):

```markdown
---
description: Glossary-writer subagent. Produces one-line definitions for project terms
after reading CONTEXT.md and a codebase sample. Use for documentation passes and audits.
mode: subagent
permission:
  edit: deny
steps: 40
color: info
---

# Glossary Writer

Read CONTEXT.md if present; skim the named files; output one-line definitions…
```

Then either invoke by description or wire a command: `commands/glossary.md` →
`Write a glossary for: $ARGUMENTS …`. And per the contract: add the row to
[Agents table](README.md#agents-8) and mention the command in the guides.

### Example C — tune the gate's cache window

The 120s TTL in `plugins/proof-of-work.ts` is a trade-off: fast iterations in a big
repo vs. stale-green risk. `GATE_CACHE_TTL_MS = 120_000` is the single knob; the
`lastState` (porcelain output) guard means a changed tree invalidates the cache
regardless of time. Extending it means editing the constant — and updating the
[Plugins table](README.md#plugins-3) + this guide's §4 description of the cache.

### Example D — docs-sync pass on this repo

```
/audit                  → pass 3 = docs drift (AGENTS.md vs code, README vs reality)
/docs-check             → inventory tables vs filesystem, README counts, guide refs
```

Both read-only. The audit's pass 3 and `/docs-check` are the contract's teeth —
run them before committing documentation changes to this repo, and treat every
finding as a must-fix (drift is a lie in the docs, and stale routing descriptions
kill component usage).

---

## 13. References

- [OpenCode: agents](https://opencode.ai/docs/agents) / [skills](https://opencode.ai/docs/skills) / [commands](https://opencode.ai/docs/commands) / [plugins](https://opencode.ai/docs/plugins)
- [OpenCode config schema](https://opencode.ai/config.json)
- [@opencode-ai/plugin SDK](https://www.npmjs.com/package/@opencode-ai/plugin)
- [cc-settings](https://github.com/darkroomengineering/cc-settings) — the lineage this repo ports
- [mattpocock/skills](https://github.com/mattpocock/skills) — the skill-writing lineage
- [WordPress Coding Standards (PHP)](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/php/)
- [WPCS on GitHub](https://github.com/WordPress/WordPress-Coding-Standards) · [PHP_CodeSniffer](https://github.com/PHPCSStandards/PHP_CodeSniffer) · [PHPCompatibility](https://github.com/PHPCompatibility/PHPCompatibility)
- [Laravel Pint](https://laravel.com/docs/pint)
- [Vite](https://vitejs.dev) · [Tailwind CSS v4](https://tailwindcss.com/docs) · [GSAP](https://gsap.com/docs) · [Lenis](https://github.com/darkroomengineering/lenis/blob/main/README.md) · [Tempus](https://github.com/darkroomengineering/tempus/blob/main/README.md) · [Three.js](https://threejs.org/docs) · [swup](https://swup.js.org)
- [WP-CLI](https://wp-cli.org) · [Composer](https://getcomposer.org)
- [Documentation hub](README.md) · [Level 1 Guide](guide-beginners.md) · [Level 3 Guide](guide-advanced.md)
