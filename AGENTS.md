# WordPress Enterprise Engineering — Snoozle Studio

> Coding standards and guardrails for AI-assisted WordPress development — enterprise-grade
> plugins and classic themes, no vibe coding. Works with OpenCode, Claude Code, Codex,
> Cursor, Copilot, Windsurf, and any AGENTS.md-compatible tool.

---

## Philosophy

Make the codebase legible to agents. Written-down conventions, skills, and rules are the
debt you owe your human engineers; every entry pays it down for both audiences at once.

WordPress specifics: we ship production code that survives Theme Review and Plugin Review,
works on PHP 8.2+, respects the plugin/theme contract (hooks, escaping, i18n, a11y, perf),
and never leaks unescaped output, raw SQL, or missing capability checks.

---

## Getting Started

1. **Read this file** — it's the baseline for how we work
2. **Use your tools naturally** — read files, search code, run builds directly
3. **Delegate when triggered** — multi-file exploration, security-sensitive code, and
   verification MUST go to subagents; don't reason your way out of it
4. **Learn the guardrails** — they exist because we hit every one of these problems

Do not over-engineer the workflow. Start simple, add complexity only when you feel friction.

---

## Response Calibration

Match output length to what was asked: a lookup gets a sentence and a `file:line`, a
multi-file change gets a brief plan and a short summary of what landed. Lead with the
answer; skip the preamble announcing what you're about to do and the recap restating the diff.

Number multi-step work as it proceeds; restate progress each turn. No AI fingerprints in
commits, PRs, or descriptions — ever (see Git).

---

## Guardrails

These rules exist because we've seen them violated repeatedly. Non-negotiable.

### Laziness Ladder (Before Writing Code)
The best code is the code you don't write. Before generating anything, stop at the
**first rung that holds**:

1. **Does this need to exist?** — if no, skip it (YAGNI). Question the request before solving it.
2. **Does this codebase already do it?** — reuse it; extend before you re-create.
3. **Does WordPress core already do it?** — use it. There is a WP function for almost everything.
4. **Does an already-installed dependency solve it?** — use it; don't add a new one.
5. **Can it be one line?** — make it one line.
6. **Only then** — write the minimum that works.

Default to deletion over addition, boring over clever, fewest files possible. No
abstractions, dependencies, or boilerplate nobody asked for.

**Lazy, not negligent.** The ladder never applies to trust-boundary/input validation,
error handling that prevents data loss, security, accessibility, i18n, or anything
explicitly requested — those are always built in full.

### Read Before Edit
**Never change code you haven't read.** Research the codebase before editing — open the
file, trace the callers, understand the context. Edit-first behavior produces shallow
fixes and regressions.

### 2-Iteration Limit
If an approach fails after **2 attempts**, STOP:
1. Summarize what you tried and why it failed
2. Present **2-3 alternative approaches** with trade-offs
3. Ask which direction to take

Never burn 6+ attempts on the same strategy. Fail fast, pivot deliberately.

### Bug Fix Scope
When fixing a bug, stay **confined to files directly related to the bug**:
- Don't refactor adjacent code "while you're in there"
- Don't upgrade dependencies as part of a bug fix
- Don't touch files outside the immediate blast radius
- A bug fix PR should be reviewable in under 2 minutes

### Completeness Is Cheap
When the complete version of the thing you're **already building** costs minutes more than
the shortcut, do the complete thing — every edge case, error path, and security check.
Bounded by scope: finish the unit you're deliberately touching; flag adjacent systems as
out of scope. The ladder decides *whether* to build; completeness decides *how thoroughly*
to finish what you've decided to build.

### Verify After Every Fix
Run the verification chain after any fix and confirm it passes **before moving on**. Never
stack untested fixes — cascading errors eat context and compound regressions.

### Pre-Commit Verification Chain (WordPress)
**Never commit code that fails the verification chain.** The chain — build →
format:all:check → phpcs → phpstan, in order, stopping at the first red — is defined
once in [docs/verification-chain.md](docs/verification-chain.md). Run it and fix what
it surfaces before committing — not after. The
`proof-of-work` plugin gates `git commit`/`git push` on these checks; never bypass it.
The gate is scoped to the session directory: `git -C <repo>` is honored, `cd`-style
command chains are exempt (use `git -C` to gate another repo explicitly).

### Failing Tests: Regression vs. Contract Change
A failing check after your change is a fork in the road:
- **Regression** — the assertion still describes correct behavior and your change broke
  it. Fix the *code*, never relax the check to go green.
- **Intentional contract change** — the requirement explicitly supersedes it. Update
  implementation and assertion *together in the same diff*, and say which contract
  changed and why.

When you can't tell which case it is, treat it as a regression and stop to confirm.
A green suite that blesses wrong behavior is worse than a red one that caught it.

### Never Fake Measurements
NEVER fabricate output from Lighthouse, bundle-size tools, performance profilers, test
runners, or build systems. If you can't run a tool, say so.

### Visual/Spatial Honesty
For WebGL, canvas, complex animations, or sub-pixel rendering — acknowledge limitations
upfront. Provide best-effort with clear TODOs, and suggest the user validate visually in
the browser (WordPress context: `npm run dev` + browser; PHP changes need a reload).

For CSS/visual bugs: if a fix doesn't work after 2 attempts, propose **3 fundamentally
different approaches** and let the user pick.

### Name the Cause
Before committing a fix, you must be able to name the specific cause in one sentence. If
you can't, you have a guess, not a cause. Especially true for CSS and viewport bugs
(Lenis/ScrollTrigger/fixed-element interactions). If the sentence requires "I think" or
"maybe," gather more signal — screenshot the broken element, inspect computed styles —
before editing.

### Fail Loud
"Done" is wrong if anything was skipped, mocked, or unverified. State it explicitly when:
- A check was skipped or relaxed
- A feature was implemented but not exercised end-to-end (e.g. UI shipped without browser
  verification)
- A claim relies on a tool, command, or service you didn't actually run

Default to surfacing uncertainty — the cheapest bugs to fix are the ones the user hears
about before they ship.

### Surface Conflicts, Don't Average
When two existing patterns contradict (two escaping styles, two query patterns, two
enqueue strategies), pick one — usually the more recent or more tested — and flag the
other for follow-up cleanup. Do **not** write code that satisfies both.

### Post-Compaction Recovery
After any compaction or context reset, **before continuing work**:
1. Re-read the task plan (todo, plan file, or issue)
2. Re-read the files you're actively modifying
3. Run `git diff --stat` to see what's changed
4. Only then continue implementation

### Neutral Exploration
When investigating code (auditing, reviewing, exploring), use **neutral prompts** that
don't bias toward a specific outcome: "analyze the logic and report all findings" — not
"find the bug". Biased prompts cause agents to manufacture issues that don't exist.

### TODO Comments Are Instructions
When you encounter a `TODO`, `FIXME`, or `HACK` comment, **implement it** — don't delete
it. Removing a TODO without doing the work is marking your own homework complete by
erasing the assignment.

### Plan Before Multi-File Changes
Once a change is broad enough that a wrong approach would mean a full rollback, state the
plan before executing it — which files you'll touch and what could break. **State it,
don't ask permission for it**; reversible in-scope work still proceeds without approval.

### Dependency Upgrades
Before upgrading major dependencies, check for breaking changes (Context7 MCP first). If
an upgrade breaks the build, **rollback immediately** to the working version. Rollback
first, research the migration, then try again with a plan. Never upgrade dependencies as
part of a bug fix.

### Recommend, Don't Override
You recommend; the user decides. When a change would alter the user's **stated direction**,
present the recommendation, say why, name the context you might be missing, and ask —
never act on it unilaterally.

### Bug Reports
When given a bug report, fix it immediately. No "should I?" questions. If something goes
sideways, stop and re-plan — don't keep pushing.

---

## Tech Stack

Default stack for Snoozle Studio WordPress work. Framework depth lives in the
`wp-plugin` / `wp-theme` skills and `docs/`.

### Core
- **WordPress 6.8+ (7.0 verified)** — classic themes and plugins (not block themes unless asked)
- **PHP 8.2+** — typed where possible, PHP 8.0+ compatible syntax
- **ACF Pro** — field groups, option pages, `acf-json/` sync
- **Composer** — dev tooling only (WPCS, Pint, stubs)

### Front-End Build
- **Vite 8 (Rolldown)** — build tool; `base` set to the theme/plugin `dist/` URL,
  `build.manifest: true`, code-splitting via `rolldownOptions`
- **Tailwind CSS v4** — CSS-first config: `@import "tailwindcss"`, `@theme` tokens in CSS,
  **no `tailwind.config.js`**
- **Prettier** + `prettier-plugin-tailwindcss` — JS/CSS/JSON formatting

### Animation & Graphics
- **Lenis** — smooth scroll (`autoRaf: false`, driven by Tempus, `data-lenis-prevent`
  for nested scrollables)
- **Tempus** — single rAF manager (`order: -1` producers, `order: 1` renders)
- **GSAP** — complex animations; `gsap.context()` + `revert()` for cleanup;
  `gsap.matchMedia()` for reduced-motion
- **Three.js** — WebGL (dynamic `import()` chunks, dispose everything)
- **swup** — optional page transitions; re-init/destroy all libs on `content:replace`

### Quality
- **WPCS 3.0** — `phpcs.xml` with `WordPress-Extra` + `WordPress-Docs` +
  `PHPCompatibility` + `Universal` (testVersion `8.2-`)
- **Laravel Pint** — PHP formatter
- **PHPStan** — `phpstan.neon` at level 8 with `szepeviktor/phpstan-wordpress`
  (WP globals/functions stubs); theme neon scans `php-stubs/acf-pro-stubs`
- **Husky** — pre-commit gate (format + phpcs + phpstan)
- **PHPUnit/wp-env** — not standard; lint + build is the proof-of-work

Always check latest version before installing: `npm info <package>` / `composer show`.

---

## WordPress Coding Standards (Non-Negotiable)

Full reference in `docs/wordpress-php-standards.md`. Load it when writing or reviewing PHP.
The summary that must never be violated:

### Naming & Structure
- Functions: lowercase `snake_case`, always prefixed with the project prefix (≥4 chars,
  e.g. `ss_`, `snoozle_`) — never `wp_`, `__`, or `_` prefixes
- Classes: `Class_Name` with underscores, one class per file, file named
  `class-{class-name}.php`; namespace `Prefix\Module\Sub_Module` (uppercase words,
  underscores); `wp`/`WordPress` namespace reserved for core
- Constants: `ALL_CAPS_WITH_UNDERSCORES`
- File names: lowercase, hyphens; text domain matches slug **with dashes**
- Global variables, options, transients, hook names: ALL prefixed

### Syntax
- **Tabs for indentation** (never spaces); spaces around operators and inside control
  structure parens
- **Long array syntax `array( ... )`** — short `[ ... ]` is prohibited by WPCS
- **Yoda conditions** for `==`/`!=`/`===`/`!==` (constant on left)
- Braces always used, `elseif` never `else if`, no `extract()`/`eval()`/`create_function()`
- Single quotes unless interpolating; no `@` error suppression; no closures as
  action/filter callbacks (they can't be removed)

### Security (escape at output, never at store)
- **Escaping matrix** (see `docs/wordpress-security.md`): `esc_html()` (text),
  `esc_attr()` (attributes), `esc_url()` (URLs — never `esc_attr( $url )`), `esc_textarea()`,
  `wp_kses_post()` (trusted-HTML content), `esc_html_e()/esc_attr_e()` for i18n
- **Sanitize input**: `sanitize_text_field()`, `absint()`, `sanitize_email()`,
  `sanitize_key()`, `sanitize_title()` — always `wp_unslash()` request data FIRST, then
  sanitize; validate before sanitize (safelists, `in_array( $x, $allowed, true )`)
- **SQL**: never concatenate values into SQL — always `$wpdb->prepare()` with unquoted
  `%s`/`%d`/`%f`/`%i` placeholders; prefer WP APIs (`get_post_meta`, `WP_Query`) over raw SQL
- **CSRF**: `wp_nonce_field()`/`wp_nonce_url()`/`wp_create_nonce()` on every state-changing
  form; verify with `check_admin_referer()`, `check_ajax_referer()`, `wp_verify_nonce()`;
  nonce action strings as specific as possible (include IDs)
- **Authorization**: nonces are NOT authorization — always pair with
  `current_user_can( 'capability' )`; `is_admin()` is not an auth check
- **File guards**: `if ( ! defined( 'ABSPATH' ) ) { exit; }` at the top of every file with
  top-level code; `uninstall.php` guarded by `WP_UNINSTALL_PLUGIN`
- **Redirects**: `wp_safe_redirect()` for user-influenced URLs
- Never commit secrets; no API keys in code; use `wp-config.php` constants or env vars

### i18n (translation-ready, always)
- Every user-facing string passes through a translation function with the text domain as
  the LAST argument: `__( 'Text', 'domain' )`, `esc_html_e( 'Text', 'domain' )`
- **Escape + translate** for attributes: `esc_attr__()`/`esc_attr_e()`; no raw `__()` in HTML
- Numbered placeholders with translators comments: `/* translators: %s: Name */`
- `load_theme_textdomain()` / `load_plugin_textdomain()` wired on the right hook

### Hooks
- Custom hook names prefixed (`snoozle_`), documented with full DocBlock above
  `do_action()`/`apply_filters()`; filters have no side effects
- Use core hook timing correctly: `after_setup_theme` (theme setup),
  `init` (CPTs, rewrites), `wp_enqueue_scripts`, `admin_enqueue_scripts`,
  `plugins_loaded`, `rest_api_init`, `register_activation_hook`/`deactivation`/`uninstall`

### Data
- Options API with `autoload: false` for anything large/rarely used; Transients for
  cached computed data
- REST routes: `permission_callback` required for non-public data, `sanitize_callback`
  + `validate_callback` per arg, `WP_Error` with machine-readable codes + `status`
- Activation: set defaults, register CPTs, `flush_rewrite_rules()`. Deactivation: clear
  temp data, flush rewrites. **Deactivation is NOT uninstall** — permanent data removal
  only in `uninstall.php`

---

## Front-End Standards

Full reference in `docs/frontend-stack.md`. Load it when writing or reviewing JS/CSS.

### JavaScript
- ES modules, `const`/`let` (no `var`), no jQuery
- Component pattern: an init function guarded by element existence, Tempus-driven rAF,
  `prefers-reduced-motion` gate, and a **cleanup function returned** for teardown
  (Lenis `.destroy()`, `gsap.context().revert()`, Tempus unsubscribe, Three.js `dispose()`)
- Heavy work lazy: dynamic `import()` chunks (Three.js, QR), IntersectionObserver-based
  init, frame-budget checks via `Tempus` `state.budget`
- GSAP: wrap all animations in `gsap.context()` scoped to the component; animate only
  `transform`/`opacity`; no `will-change: transform` on ancestors of `position: fixed`
- Lenis: `new Lenis({ autoRaf: false })` + `Tempus.add(({ time }) => lenis.raf(time), { order: -1 })`;
  `lenis.on('scroll', ScrollTrigger.update)`; `data-lenis-prevent` for nested scrollables;
  gate whole init behind reduced-motion
- ScrollTrigger: `ScrollTrigger.refresh()` after fonts/images/DOM changes; never animate
  a `pin`ped element itself

### CSS
- Tailwind v4 CSS-first: tokens in `@theme`, `@source` for PHP template dirs if
  auto-detection misses them, custom utilities via `@utility`
- Fonts: `@font-face` with `font-display: swap`, local woff2, `unicode-range` subsets
- Use `h-dvh` not `h-screen`; touch targets ≥ 44×44px; contrast ≥ 4.5:1; honor
  `prefers-reduced-motion`; relative units; no `* { transition: all }`

### Accessibility (WCAG 2.2 AA)
- Skip link first in body (`wp_body_open()`), visible on keyboard focus
- Semantic elements: no `<div onClick>`; `aria-label` on icon-only buttons; labels on all
  inputs (placeholder is NOT a label); `aria-current="page"` on active nav; focus styles
  never removed without a more visible replacement; content usable with JS disabled
- Images: descriptive `alt` (decorative: `alt=""` or `aria-hidden`)

---

## Git

- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `perf:`, `style:`, `test:`
- Small, atomic commits; never force push to `main`
- Never commit `node_modules`, `dist/`, `.env`, or local DB dumps

### Stealth Mode (Mandatory)
No AI fingerprints in git history, PRs, or descriptions. Ever.
- No `Co-Authored-By` lines mentioning any AI
- No "Generated with AI", robot emoji, or "automated by" language
- Commit messages: conventional format, nothing else

---

## Documentation Contract (This Repo)

**Every change to THIS repo (agents/, skills/, commands/, plugins/, templates/,
scripts/, .github/workflows/, opencode.json, tui.json, setup.ps1, scaffold.cmd)
must update the documentation in the
same change.** A change without its doc sync is incomplete — do not report it done.

Documentation lives in: `README.md` (front door), `docs/README.md` (hub + inventory),
`docs/guide-beginners.md` (Level 1), `docs/guide-pro.md` (Level 2),
`docs/guide-advanced.md` (Level 3), and the reference docs in `docs/`. The full
contract with per-component targets: `docs/README.md`
"Documentation Contract".

Mandatory sync targets (summary):

| Changed | Also update |
|---|---|
| agent / skill | its `description` frontmatter (the routing table) + hub inventory row |
| command | its `description` + hub inventory row + guide examples that use it |
| plugin | its docblock + hub inventory row + guide-pro § Plugins |
| template | hub inventory row + guide-pro § Templates + scaffolder agent if flow changed |
| setup.ps1 / scaffold.cmd | hub scripts table + README scaffolding section + guide-pro § Scaffolding |
| opencode.json / tui.json | README "What's inside" + guide-pro § Permissions/MCP |
| anything user-facing | Level 1 guide examples (they must not lie) |

**New components are not done until listed in**: the hub inventory, README "What's
inside" (and skills/commands indexes), and a guide if a human invokes it.

**Verification**: run `/docs-check` (inventory vs filesystem drift) or `/audit` pass 3
before committing documentation-affecting changes to this repo. Drift is a finding,
not a nit. `setup.ps1 -Validate` additionally enforces frontmatter/name rules.

---

## External Libraries

**Search before building** — does WP core, an installed dependency, or a one-liner cover
it? Before implementing with any external library:
1. Fetch current docs via Context7 MCP — don't assume API knowledge
2. Check latest version (`npm info <package>`, `composer show`)
3. Verify it plays well with WordPress enqueueing (no global jQuery assumptions)

---

## Context Hygiene

### Tool Output Offloading
When a tool returns output exceeding ~2000 tokens (large search results, verbose logs),
write it to a scratch file and return a summary with the file path instead of carrying the
full output in context.

### Information Placement
Place critical information at the **beginning** and **end** of context. The middle
receives less attention (lost-in-middle effect).

---

## Knowledge Routing

Use this table to decide where a piece of knowledge belongs:

| Situation | Where it belongs |
|---|---|
| Personal workflow preference | auto-memory (user/feedback) |
| Active project state, deadlines, blockers | auto-memory (project) |
| Architecture decision the team must follow | `AGENTS.md` "Self-Evolving Learnings" + `/share-learning` |
| Library gotcha that affects everyone | `AGENTS.md` learnings log + `/share-learning` |
| Convention ("All template output is escaped at echo time") | `AGENTS.md` learnings log + `/share-learning` |
| Incident postmortem worth team awareness | `AGENTS.md` learnings log + `/share-learning` |

**Rule of thumb:** if another project's agent would benefit from knowing it, record it in
the learnings log. Otherwise let auto-memory handle it.

## Self-Evolving Learnings (agent convention)

After completing a session, if you hit a non-obvious bug, discovered a useful pattern, or
found an edge case, append a dated entry to the project's `AGENTS.md` under
`## Self-Evolving Learnings`:

```
- [YYYY-MM-DD] <category>: <one-line learning>
```

Categories: wordpress, php, security, gsap, lenis, vite, tailwind, build, tooling.
Keep entries terse and factual — one line each.

- [2026-08-04] tooling: Pint's laravel preset conflicts with WPCS (spaces/tabs, `array()` vs
  `[]`, Yoda, `array( $x )` spacing, `new self()` parens, function/class brace placement) —
  pint.json must disable indentation_type, array_indentation, statement_indentation,
  spaces_inside_parentheses, no_spaces_around_offset, array_syntax, yoda_style,
  unary_operator_spaces, phpdoc_no_package, function_declaration, braces_position,
  class_definition, new_with_parentheses, trim_array_spaces, binary_operator_spaces,
  blank_line_after_opening_tag; set concat_space to "one". phpcs is the style authority.
- [2026-08-04] tooling: `ref="Universal"` in phpcs.xml loads EVERY sniff in the namespace —
  including the mutually exclusive RequireExitDieParentheses/DisallowExitDieParentheses
  pair. WordPress-Extra already includes a curated Universal subset; PHPCompatibilityWP
  no longer exists in phpcompatibility 9.x (use PHPCompatibility).
- [2026-08-04] wordpress: enqueueing Vite hashed assets with $ver = null trips
  WordPress.WP.EnqueuedResourceParameters.MissingVersion — the hash IS the cache-buster;
  wrap in phpcs:disable/enable with a comment instead of passing a fake version.
- [2026-08-04] tooling: Local by Flywheel's bundled PHP has openssl disabled in php.ini —
  composer install fails TLS; enable per-invocation with a temp php.ini
  (extension=openssl + mbstring) instead of editing Local's php.ini.
- [2026-08-04] tooling: PowerShell 5.1 Set-Content -Encoding UTF8 writes a BOM which
  breaks JSON.parse — use [IO.File]::WriteAllText with UTF8Encoding($false); Get-Content
  defaults to ANSI and mangles UTF-8 — keep .ps1 and template files ASCII-only.
- [2026-08-04] tooling: PowerShell 5.1 parses `$var:` as a drive reference (use `${var}:`)
  and hashtable keys are case-insensitive ({PREFIX} vs {Prefix} collide — use a
  Dictionary[string,string]); piping a native command to Select-Object -First kills the
  upstream process early.
- [2026-08-04] tooling: Local's Windows "Site Shell" opens cmd.exe by default — `&` call
  syntax dies with "& was unexpected at this time" and `$HOME` isn't expanded. Shell-
  agnostic entry point: a .cmd wrapper forwarding %* to `powershell -NoProfile
  -ExecutionPolicy Bypass -File`.
- [2026-08-04] tooling: Local bundles PHP under two roots — %APPDATA%\Local\lightning-
  services\... (site-shell PATH) and Program Files (x86)\Local\resources\extraResources\
  lightning-services\... — detect Local's PHP by matching "lightning-services" anywhere
  in the path, never a fixed prefix.
- [2026-08-04] tooling: templates/theme package.json must call `php vendor/bin/pint` — a
  bare `vendor/bin/pint` (forward slash) fails under npm scripts on Windows cmd, breaking
  format:all:check and the pre-commit gate.
- [2026-08-04] tooling: templates/theme pint.json must disable phpdoc_align +
  no_blank_lines_after_phpdoc, and docblocks must use single-space @param with exactly one
  blank line after the file comment — the template's aligned style failed its own phpcs
  (Squiz.Commenting.FileComment.SpacingAfterComment).
- [2026-08-04] wordpress: functions.php requires configure/nav-walker.php — the template
  must ship a WPCS-compliant stub ({Prefix}_Header_Nav_Walker extends Walker_Nav_Menu) with
  phpcs:disable WordPress.Files.FileName; the filename is fixed by the boot chain, and the
  sniff fires at line 0 so only phpcs:disable (not :ignore) suppresses it.
- [2026-08-04] tooling: `npx skills add ... -a opencode -g` (skills CLI 1.5.x) writes to
  `~\.agents\skills\` despite the docs' global-path table — move the skill dirs into
  `~/.config/opencode/skills/` after install so they're git-tracked and docs-checkable.
  Vendored gsap-* skills: never edit in place; refresh via `npx skills update -a opencode -g`.
- [2026-08-05] tooling: bun's text bun.lock is JSON-with-trailing-commas by design in
  every bun version — never strict JSON; validate it with bun itself
  (`bun install --frozen-lockfile --dry-run`), never jq. Resync a stale lockfile with
  `bun install --lockfile-only` (no --frozen-lockfile — frozen rejects the rewrite).
- [2026-08-05] tooling: cmd.exe splits an executable token at `/` — `vendor/bin/phpcs`
  parses as the command `vendor` plus a switch; composer bins must run as
  `vendor\bin\<tool>.bat` on win32 (backslash extensionless forms DO resolve via
  PATHEXT — probe-verified — but the forward-slash canonical form never does).
- [2026-08-05] tooling: a trigger regex `git(\.exe)?\s+(push|commit)` silently
  misses `git -C <path> push/commit` — the option precedes the verb. Gate/trigger
  patterns need an optional `-C <path>` clause; verified end-to-end by driving
  proof-of-work.ts via bun against fake gated repos (per-target cache keyed by
  HEAD + porcelain, cache hits within 120s, invalidation on new HEAD).
- [2026-08-07] tooling: template JS must avoid template-literal `${ident}`
  interpolation — setup.ps1's dry-run stray-token guard regex
  `\{[a-zA-Z_][a-zA-Z0-9_-]*\}` flags `{ident}` inside it (comments included,
  so don't write brace-token examples in template comments either); use string
  concatenation. The shipped hero.js example documents this in place.
