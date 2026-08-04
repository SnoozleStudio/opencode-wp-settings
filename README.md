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
setup.ps1             Validation + project scaffolding (Windows)
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

## License

MIT. Fork freely; keep the stealth-mode rule — the history belongs to the engineers.
