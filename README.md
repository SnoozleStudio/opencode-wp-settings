# OpenCode WordPress Settings

Production-ready WordPress development settings for OpenCode.

A structured OpenCode configuration for building and maintaining custom WordPress
themes and plugins with coding standards, automated checks, and project-specific
instructions.

![WordPress CS](https://img.shields.io/badge/WPCS-Compliant-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![OpenCode](https://img.shields.io/badge/OpenCode-Config-purple.svg)

**What this solves.** Generic AI models are trained on a sea of WordPress code — and
most of that sea is legacy, unmaintained, and unsafe. This config encodes the WordPress
engineering discipline — WPCS, strict PHPStan typing, the escaping matrix, automated
verification — so OpenCode follows an established workflow instead of generating
generic PHP.

**Who it's for.** Developers and agencies building custom WordPress themes and plugins.
This repo IS your global OpenCode config: it lives at `~/.config/opencode/` and is
loaded automatically in every project. Updates = `git pull`.

A port of [darkroomengineering/cc-settings](https://github.com/darkroomengineering/cc-settings)
with engineering discipline from [mattpocock/skills](https://github.com/mattpocock/skills).

> **Documentation** — start here, then go deeper:
>
> - [Level 1 Guide — AI-driven workflows with example prompts](docs/guide-beginners.md) — for beginners
> - [Level 2 Guide — internals & extension](docs/guide-pro.md) — for developers
> - [Documentation Hub — every component indexed](docs/README.md)
>
> **Every change to this repo must stay synced with the documentation** — that's a
> binding contract, see [AGENTS.md](AGENTS.md) and the [hub](docs/README.md#documentation-contract).

---

## What you get

- **No vibe coding, enforced** — a hook plugin blocks `git commit` and `git push`
  until build, format, phpcs, and PHPStan are all green (escape hatch:
  `--no-verify` / `SKIP_GATE=1` — never the norm)
- **WordPress code that ships safe** — escaping at output, sanitization, nonces +
  capability checks, `$wpdb->prepare()` — encoded as rules, with a dedicated
  security-auditor agent covering the full attack surface
- **Scaffolding that starts compliant** — one command scaffolds a classic theme or
  plugin that passes Theme/Plugin Review from the first file: WPCS templates, the
  template-hierarchy boot chain, and Vite/Tailwind wired in
- **An AI that knows your stack** — GSAP, Lenis, Tempus, and Tailwind discipline
  loaded on demand via skills, so the front end meets the same bar as the back end

## Quick start in 3 steps

1. **Install** — clone into your OpenCode config dir (or copy the files in; if the
   directory already exists, clone into a temp folder and merge):

   ```powershell
   git clone https://github.com/SnoozleStudio/opencode-wp-settings.git "$HOME\.config\opencode"
   ```

2. **Restart OpenCode** — the config loads for every session automatically
3. **Try it** — open any WordPress theme or plugin project and invoke a command:
   - `/theme` — Scaffold a WPCS-compliant classic theme
   - `/fix` — Fix an issue with mandatory WPCS + escaping verification
   - `/audit` — Run a full security & code quality pass

   Classic-theme first — the config targets classic themes (not block themes):
   WPCS templates, the template-hierarchy boot chain, and Vite/Tailwind — all
   scaffolded from day one.

Updates = `git pull`. Non-destructive: project-level `opencode.json` / `.opencode/`
configs merge over the global one.

---

## Why?

Generic AI models are trained on a sea of WordPress code — and most of that sea is
legacy, unmaintained, and unsafe. Left to its own devices, an AI will happily produce:

- **Escaping that isn't** — unescaped output, or the wrong escaping function for the
  context, because the escaping matrix is a dense contract
- **Raw SQL and missing nonces** — code that works on your laptop and gets a client's
  site hacked in production
- **Unprefixed globals and hooks** — functions, options, and hooks that collide with
  other plugins, or that WordPress core already provides
- **"It works on my machine" fixes** — no build, no lint, no verification, so broken
  code ships

The root cause is that WPCS (WordPress Coding Standards) is exactly the kind of
opinionated contract generic models get wrong: the average plugin violates it, so the
average generated code violates it too.

This repo closes that gap with engineering discipline, not hope:

- **Written-down conventions** — `AGENTS.md` + reference docs encode the house rules
  every session must follow
- **Skills that teach** — `wp-plugin`, `wp-theme`, `wp-security-audit`… load the
  discipline at the moment it's needed
- **Verification you can't skip** — the `proof-of-work` plugin physically blocks
  commits/pushes until build + format + phpcs + phpstan are green
- **Scaffolding that starts right** — templates ship WPCS-compliant from the first
  file, so the AI never writes from a blank slate

## At a glance

### 🔄 How OpenCode enforces quality in your workflow

```text
[ User Request ] ──► [ /fix or /build Command ]
                           │
                           ▼
            [ Subagent Maps & Plans ]
                           │
                           ▼
         [ PHP Edits via WPCS & Escaping Matrix ]
                           │
                           ▼
     ┌────────────────────────────────────────────┐
     │  Proof-of-Work Gate (Automatic Hook)       │
     ├────────────────────────────────────────────┤
     │  4-step verification chain, stop at red    │
     │  (docs/verification-chain.md)              │
     └────────────────────────────────────────────┘
                           │
                 [ ❌ FAIL? Block Commit / Push ]
                 [ ✅ PASS? Clean Git Push ]
```

---

## What's inside

```
AGENTS.md             Portable coding standards (guardrails, WP + front-end stack, git)
LICENSE               MIT license (incl. upstream attribution: cc-settings, mattpocock/skills)
opencode.json         Global config: permission allow/ask/deny lists, MCP servers
tui.json              TUI plugins (subagent statusline)
agents/               8 subagents (explore, implementer, planner, reviewer,
                      security-auditor, tester, scaffolder, maestro)
skills/               26 skills (wp-plugin, wp-theme, wp-security-audit, fix, verify,
                      review, refactor, tdd, gsap-core/gsap-scrolltrigger/... vendored
                      from greensock/gsap-skills, ...)
commands/             18 slash commands (/fix /build /review /verify /ship /audit
                      /docs-check /plugin /theme /section /phpcs /check /grill ...)
plugins/              3 hook plugins (proof-of-work gate, phpcs-watch, session-context)
                      + plugins/lib/run.ts (shared shell runner)
docs/                 Documentation hub + reference docs + 2 guides
tickets/              Working ticket lists (audit fixes, plans)
templates/            Scaffolding for new theme and plugin projects
setup.ps1             Validation + project scaffolding (Windows, Local site-shell aware)
scaffold.cmd          Shell-agnostic wrapper for setup.ps1 (cmd, Git Bash, PowerShell)
```

## How it works

```
You type:  "/fix the mobile menu"
     │
     ▼
commands/fix.md ──► fix skill ──► explore (maps) → implementer (edits) → verification chain
     │
     └─ plugins watch the pipeline: phpcs-watch lints every PHP edit,
        proof-of-work gates git push/commit on a green chain
```

You describe the work in plain English; commands, skills, and agents handle the
discipline. The full wiring lives in the [Documentation Hub](docs/README.md#dependency-map).

## Guardrails at a glance

- **Verification chain** — build → format:all:check → phpcs → phpstan, in order,
  stopping at the first red, enforced before every commit
  ([docs/verification-chain.md](docs/verification-chain.md)).
  The `proof-of-work` plugin blocks `git push`/`git commit` on a red chain (skip with
  `--no-verify` or `SKIP_GATE=1` — but that's the escape hatch, not the norm; the gate is
  scoped to the session directory — `git -C <repo>` is honored, bare `cd` chains are exempt)
- **WordPress contract** — escaping at output, `wp_unslash` before sanitize, nonces +
  capabilities, `$wpdb->prepare`, i18n everywhere, prefixed names, ABSPATH guards
- **Front-end discipline** — ES modules, Tempus-driven rAF, reduced-motion gates,
  cleanup returned from every component, dynamic `import()` for heavy work
- **Stealth mode** — no AI fingerprints in commits/PRs, ever

## Common commands

| You say | What happens |
|---|---|
| `fix the hero animation` | `/fix` — explore → reproduce → diagnose → implement → verify |
| `build a pricing section` | `/build` — grill for alignment, then plan → implement → verify |
| `create a new plugin` | `/plugin` — scaffolds from `templates/plugin` |
| `create a new theme` | `/theme` — scaffolds from `templates/theme` |
| `review my changes` | `/review` — two-axis review (standards + spec) + phpcs |
| `ship it` | `/ship` — full proof-of-work gate, then commit |
| `audit the codebase` | `/audit` — maintainability + security + docs drift |
| `check this is correct` | `/verify` — adversarial finder/adversary/referee pass |
| `is the docs synced?` | `/docs-check` — inventory vs filesystem drift check |
| `security review` | security-auditor agent — full WP attack surface |
| `done for today` | `/handoff` — one-page session transfer |

All 18 commands, with the skill/agent each invokes, are indexed in the
[Documentation Hub](docs/README.md#commands-18).

## Skills index

- **WordPress**: `wp-plugin`, `wp-theme`, `wp-security-audit`, `wp-accessibility`,
  `wp-performance`, `wp-i18n`
- **Engineering**: `fix`, `verify`, `review`, `refactor`, `tdd`, `diagnosing-bugs`,
  `research`, `domain-modeling`
- **Productivity**: `grill-me`, `grill-with-docs`, `to-spec`, `to-tickets`, `handoff`,
  `share-learning`
- **Vendored (upstream)**: `gsap-core`, `gsap-timeline`, `gsap-scrolltrigger`,
  `gsap-plugins`, `gsap-utils`, `gsap-performance` — official GSAP skills copied
  unedited from [greensock/gsap-skills](https://github.com/greensock/gsap-skills);
  refresh via `npx skills update -a opencode -g`, never edit

Skills auto-match from their descriptions; load [docs/skill-authoring.md](docs/skill-authoring.md)
before adding new ones.

## Scaffolding new projects

```powershell
.\setup.ps1 -NewTheme ..\wp-content\themes\mytheme -Slug mytheme -Prefix mt_ -Name "My Theme"
.\setup.ps1 -NewPlugin .\my-plugin -Slug my-plugin -Prefix myp_ -Name "My Plugin"
.\setup.ps1 -Validate
```

Then `npm install && composer install` in the project and run the verification chain.

## Scaffolding from a Local site shell

Works with Local 10.x (tested on 10.1.1+6939). Open a site and click **Site Shell**
(right-click the site → *Site Shell*): the shell starts at the site root,
`C:\Users\<user>\Local Sites\<site>\app\public` — a WordPress root. On Windows Local's
site shell opens **Command Prompt by default** (PowerShell/Windows Terminal only when
set in Local > Preferences), so the entry point is the cmd-native `scaffold.cmd`
wrapper — it forwards every argument to `setup.ps1` and works from cmd, Git Bash and
PowerShell alike:

```cmd
:: From the site shell (root auto-detected by walking up for wp-load.php)
"%USERPROFILE%\.config\opencode\scaffold.cmd" -Theme mytheme -Prefix mt_ -Name "My Theme"
"%USERPROFILE%\.config\opencode\scaffold.cmd" -Plugin my-plugin -Install
```

Optionally register the config dir on your user PATH once — then it's a bare
`scaffold -Theme ...` from any shell. Prefer the env-var editor over `setx PATH
"%USERPROFILE%\.config\opencode;%PATH%"` — setx truncates PATH beyond 1024 chars.

Prefer PowerShell? Switch Local > Preferences → Shell to PowerShell/Windows Terminal
and use the direct form instead:

```powershell
& "$HOME\.config\opencode\setup.ps1" -Theme mytheme -Prefix mt_ -Name "My Theme"
```

`setup.ps1` also targets a site from any directory (no site shell needed):

```powershell
& "$HOME\.config\opencode\setup.ps1" -Site mysite -Theme mytheme -Install
```

- `-Theme <slug>` / `-Plugin <slug>` scaffold into `wp-content\themes\<slug>` /
  `wp-content\plugins\<slug>`; the slug becomes the folder name, text domain and
  prefix base
- `-Site <name>` resolves `{Local Sites}\<name>\app\public`; `-SitesDir` overrides the
  sites folder. From the site shell no `-Site` is needed — the script walks up from
  the current directory until it finds `wp-load.php`
- `-Install` runs `npm install` + `composer install`. Local's bundled PHP ships with
  openssl not enabled in its `php.ini` (composer TLS fails), so `-Install` copies the
  ini to a temp file with openssl enabled and runs composer against it via `PHPRC`
  (environment restored afterwards; system PHP installs are used untouched)
- Non-empty target dirs are refused without `-Force` (scaffold merges over existing
  files, keeps anything extra)
- The site shell puts WP-CLI on PATH, so activation is one command:
  `wp theme activate mytheme` / `wp plugin activate my-plugin` (or wp-admin:
  Appearance > Themes / Plugins). For themes, sync ACF field groups from `acf-json/`
  on the ACF → Sync page, then `npm run build`

## Reference docs

| Doc | Read it when |
|---|---|
| [wordpress-php-standards.md](docs/wordpress-php-standards.md) | writing or reviewing PHP |
| [wordpress-security.md](docs/wordpress-security.md) | anything touching input, output, auth |
| [wordpress-plugin-architecture.md](docs/wordpress-plugin-architecture.md) | building plugins |
| [wordpress-theme-architecture.md](docs/wordpress-theme-architecture.md) | building themes |
| [frontend-stack.md](docs/frontend-stack.md) | Vite/Tailwind/GSAP/Lenis/Tempus/Three |
| [accessibility.md](docs/accessibility.md) | WCAG 2.2 AA |
| [performance.md](docs/performance.md) | page speed, web vitals |
| [verification-chain.md](docs/verification-chain.md) | the canonical proof-of-work chain |
| [skill-authoring.md](docs/skill-authoring.md) | writing new skills |

## License

MIT. Fork freely; keep the stealth-mode rule — the history belongs to the engineers.

## 🤝 Contributing & Feedback

This config is built for real-world production setups. If you find edge cases in
WordPress Coding Standards or have ideas for improving the subagent workflows:

1. Open an [Issue](https://github.com/SnoozleStudio/opencode-wp-settings/issues) for discussion.
2. Submit a PR with updated skills or docs (ensure docs remain synced per `AGENTS.md`).
