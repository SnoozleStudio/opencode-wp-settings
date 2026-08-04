# OpenCode WordPress Settings — Snoozle Studio

Enterprise-grade OpenCode configuration for WordPress plugin and classic theme
development. A port of [darkroomengineering/cc-settings](https://github.com/darkroomengineering/cc-settings)
with engineering discipline from [mattpocock/skills](https://github.com/mattpocock/skills) —
no vibe coding, real production code.

**This repo IS your global OpenCode config.** It lives at `~/.config/opencode/` and is
loaded automatically in every project. Updates = `git pull`.

## What's inside

```
AGENTS.md             Portable coding standards (guardrails, WP + front-end stack, git)
opencode.json         Global config: permission allow/ask/deny lists, MCP servers
agents/               8 subagents (explore, implementer, planner, reviewer,
                      security-auditor, tester, scaffolder, maestro)
skills/               20 skills (wp-plugin, wp-theme, wp-security-audit, fix, verify,
                      review, refactor, tdd, diagnosing-bugs, grill-me, to-spec, ...)
commands/             17 slash commands (/fix /build /review /verify /ship /audit
                      /plugin /theme /section /phpcs /check /grill /spec ...)
plugins/              3 hook plugins (proof-of-work gate, phpcs-watch, session context)
docs/                 8 reference docs loaded on-demand by skills
templates/            Scaffolding for new theme and plugin projects
setup.ps1             Validation + project scaffolding (Windows, Local site-shell aware)
scaffold.cmd          Shell-agnostic wrapper for setup.ps1 (cmd, Git Bash, PowerShell)
```

## Install

Nothing to install — clone/copy into `~/.config/opencode/`:

```powershell
git clone <this-repo> "$HOME\.config\opencode"
```

The config loads for every OpenCode session automatically. Restart OpenCode after
updating. Non-destructive: project-level `opencode.json` / `.opencode/` configs merge
over the global one.

## Guardrails at a glance

- **Verification chain** — `npm run build` → `npm run format:all:check` →
  `vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M` before every commit.
  The `proof-of-work` plugin blocks `git push`/`git commit` on a red chain (skip with
  `--no-verify` or `SKIP_GATE=1` — but that's the escape hatch, not the norm)
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
| `security review` | security-auditor agent — full WP attack surface |
| `done for today` | `/handoff` — one-page session transfer |

## Skills index

- **WordPress**: `wp-plugin`, `wp-theme`, `wp-security-audit`, `wp-accessibility`,
  `wp-performance`, `wp-i18n`
- **Engineering**: `fix`, `verify`, `review`, `refactor`, `tdd`, `diagnosing-bugs`,
  `research`, `domain-modeling`
- **Productivity**: `grill-me`, `grill-with-docs`, `to-spec`, `to-tickets`, `handoff`,
  `share-learning`

Skills auto-match from their descriptions; load `docs/skill-authoring.md` before adding
new ones.

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
  openssl/mbstring disabled in its `php.ini`, so `-Install` copies the ini to a temp
  file with both extensions enabled and runs composer against it via `PHPRC`
  (environment restored afterwards; system PHP installs are used untouched)
- Non-empty target dirs are refused without `-Force` (scaffold merges over existing
  files, keeps anything extra)
- The site shell puts WP-CLI on PATH, so activation is one command:
  `wp theme activate mytheme` / `wp plugin activate my-plugin` (or wp-admin:
  Appearance > Themes / Plugins). For themes, sync ACF field groups from `acf-json/`
  on the ACF → Sync page, then `npm run build`

## License

MIT. Fork freely; keep the stealth-mode rule — the history belongs to the engineers.
