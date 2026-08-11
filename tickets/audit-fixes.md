# Audit Fixes — Tickets

Tracer-bullet tickets from the full read-only audit (passes 1-3, 2026-08-05). All
findings were verified before ticketing; severity and CONFIRMED/PLAUSIBLE status are
carried over. Every ticket touches THIS repo, so the documentation contract applies:
docs sync in the same change as the code.

## Execution order

1. **Wave A (parallel — distinct files):** T1, T2, T3, T5, T8, T9, T10
2. **Wave B (parallel):** T4, T6, T11, T13, T15, T16 — then T7 (after T6, same file),
   T12 (after T2, same file)
3. **Wave C (parallel):** T14, T18 (after T3/T5/T8)
4. **Wave D:** T17 (after T14)
5. **T19** — final verification, after everything else

---

## [x] T1. Restrict explore agent's bash permissions

- **Blocked by**: none
- **Blocks**: none
- **Files**: `agents/explore.md`
- **Acceptance**: frontmatter `bash` becomes `"*": "ask"` plus a scoped allowlist
  (`rg`, `grep`, `Get-ChildItem`, `git status/log/diff/show`) mirroring
  `security-auditor.md`; `opencode debug agent explore` shows ask as the default;
  read-only exploration flows unchanged.

## [x] T2. Close the permission-matrix execution holes

- **Blocked by**: none
- **Blocks**: T12
- **Files**: `opencode.json`
- **Acceptance**: `"bunx *": "allow"` (line 17) removed; `"npm install*": "allow"`
  (line 8) narrowed to bare `"npm install": "allow"`; `"npx -y chrome-devtools-mcp*":
  "allow"` (line 13) removed; destructive-deny precedence (denies after allows)
  preserved.

## [x] T3. Harden phpcs-watch path handling

- **Blocked by**: none
- **Blocks**: T18
- **Files**: `plugins/phpcs-watch.ts`
- **Acceptance**: `filePath` validated against `^[\w\-./\\]+$` (reject otherwise with
  a clear message) and passed to `cmd.exe` as a quoted single token (line 66); a
  file named `x.php & <cmd>` cannot inject; normal `.php` edits still lint.

## [x] T4. Wire up the plugin template's dead classes + activation hook

- **Blocked by**: none
- **Blocks**: none
- **Files**: `templates/plugin/{plugin-slug}.php`, hub Templates table
  (`docs/README.md:201-204`), `docs/guide-pro.md` § Templates if wording changes
- **Acceptance**: scaffolded plugin requires `admin/class-{prefix}-admin.php` and
  `public/class-{prefix}-public.php`; `register_activation_hook` calls
  `flush_rewrite_rules()`; activation works and CPT permalinks resolve without a
  manual flush; template still passes the token-substitution check
  (`setup.ps1 -Validate` + scaffolder dry run).

## [x] T5. Fix proof-of-work gate bypasses

- **Blocked by**: none
- **Blocks**: T18
- **Files**: `plugins/proof-of-work.ts`
- **Acceptance**: skip check (line 91) matches standalone tokens only
  `/(^|\s)(--no-verify|HUSKY=0|SKIP_GATE=1)(\s|$)/i` — a commit message containing
  `SKIP_GATE=1` no longer disables the gate; trigger regex (line 90) matches
  `git(\.exe)?\s+(push|commit)`; `cd <other-repo>; git commit` (lines 92-116) either
  resolves the target repo (`git -C`) or warns + skips with a visible message;
  normal gated flow and standalone `SKIP_GATE=1` still work.

## [x] T6. Validate setup.ps1 inputs

- **Blocked by**: none
- **Blocks**: T7
- **Files**: `setup.ps1`
- **Acceptance**: `Resolve-Args` rejects slugs not matching `^[a-z0-9][a-z0-9-]*$`,
  prefixes not matching `^[a-z_][a-z0-9_]*$`, and `-Site`/`-Theme`/`-Plugin` values
  containing `..`, `\`, `/`, `:`, or quotes — each with a clear FAIL message and
  exit 1; valid inputs behave exactly as before.

## [x] T7. Remove the dead double-write in setup.ps1

- **Blocked by**: T6
- **Blocks**: none
- **Files**: `setup.ps1`
- **Acceptance**: lines 155-156 (`Set-Content -Encoding UTF8`) deleted; each
  scaffolded file written once via `WriteAllText` (no BOM); scaffold output
  byte-identical to before.

## [x] T8. Sanitize branch name in session-context

- **Blocked by**: none
- **Blocks**: T18
- **Files**: `plugins/session-context.ts`
- **Acceptance**: branch name filtered to `[A-Za-z0-9_\-./]` before interpolation
  into the system prompt (line 54); a hostile branch name renders inert; normal
  `Git state:` line unchanged.

## [x] T9. Untrack scaffold.log + harden .gitignore

- **Blocked by**: none
- **Blocks**: none
- **Files**: repo root `scaffold.log`, `.gitignore`
- **Acceptance**: `git rm --cached scaffold.log` done; `.gitignore` gains `*.log`
  and `.env*`; `git ls-files` shows no `scaffold.log`.

## [x] T10. Fix stale PHPCompatibilityWP references

- **Blocked by**: none
- **Blocks**: none
- **Files**: `commands/plugin.md:7`, `templates/plugin/phpcs.xml:3`,
  `templates/theme/phpcs.xml:3` (same drift, found during the fix)
- **Acceptance**: both templates' ruleset descriptions and the command say
  `PHPCompatibility`; `grep -ri PHPCompatibilityWP` returns zero matches outside the
  learnings log (`AGENTS.md`) and the historical note in guide-pro — both of which
  document the gotcha and stay.

## [x] T11. Rename commands/docs.md → commands/docs-check.md

- **Blocked by**: none
- **Blocks**: none
- **Files**: `commands/docs.md` (rename), `docs/README.md:171` (row path),
  `README.md` (common-commands table + "What's inside" tree line),
  `AGENTS.md` (/docs-check mentions), `docs/guide-pro.md` (/docs-check mentions)
- **Acceptance**: `/docs-check` resolves as a command and `/docs` no longer exists;
  `grep -r "commands/docs.md"` returns zero; opencode docs confirm filename = name
  (no `name` frontmatter for commands); `setup.ps1 -Validate` passes.

## [x] T12. Add win32 secret-deny patterns

- **Blocked by**: T2
- **Blocks**: none
- **Files**: `opencode.json`
- **Acceptance**: deny list gains win32 shapes; empirically verified via probe:
  the first out-of-workspace read (`C:\Users\psnoo\.ssh\*`) prompted at the
  `external_directory` layer (default `ask` — confirmed in opencode.log, action=ask),
  and bash-layer deny patterns match command strings literally (`Get-Content
  $env:USERPROFILE/.ssh/*` etc.). Read-layer patterns (`*\\.ssh\\*` backslash forms —
  the matcher receives relative backslash paths on win32) added as defense-in-depth;
  their match was not conclusively provable in a running session (config hot-reload
  unverified) — confirm once in a fresh session. POSIX `~` patterns untouched.

## [x] T13. Add phpstan to the 10 abbreviated chain copies

- **Blocked by**: none
- **Blocks**: none
- **Files**: `commands/fix.md`, `commands/refactor.md`, `commands/ship.md`,
  `skills/fix/SKILL.md`, `skills/refactor/SKILL.md`, `skills/diagnosing-bugs/SKILL.md`,
  `skills/tdd/SKILL.md`, `skills/wp-theme/SKILL.md`, `skills/wp-plugin/SKILL.md`,
  `skills/wp-security-audit/SKILL.md`
- **Acceptance**: every verification-chain block in `commands/` and `skills/` lists
  all four steps incl. `vendor/bin/phpstan analyse --no-progress --memory-limit=1G`;
  no copy loses the phpstan line.

## [x] T14. Canonicalize the verification chain

- **Blocked by**: none
- **Blocks**: T17
- **Files**: new `docs/verification-chain.md`; replace inline full-chain copies in
  `AGENTS.md`, `README.md` (diagram + guardrails), `agents/implementer.md`,
  `agents/tester.md`, `docs/guide-beginners.md`, `docs/guide-pro.md`,
  `docs/README.md`, `docs/wordpress-plugin-architecture.md`,
  `docs/wordpress-theme-architecture.md`, `setup.ps1`; hub Reference docs index
  (`docs/README.md:60-72`) + README Reference docs table get a
  `verification-chain.md` row. Do NOT touch `plugins/proof-of-work.ts` (the gate
  inlines the chain deliberately).
- **Acceptance**: canonical doc exists and is indexed; ≤3 inline full-chain copies
  remain repo-wide (the gate + the canonical doc + setup.ps1's "Next steps" UX
  output); all others reference the doc; `/docs-check` green.
- **Recorded deviations**: setup.ps1 keeps its chain text — it is runtime UX output
  to a scaffolded project that does not have this repo's docs (not a doc copy);
  docs/README.md:240 shorthand kept (wiring diagram, not a copy). Scope grew to the
  4 skill code blocks (tdd/wp-plugin/wp-security-audit/wp-theme), commands/ship.md,
  skills/refactor.md, and guide-beginners (/ship walkthrough + glossary) — the
  "≤3 copies" acceptance demanded it.

## [x] T15. Doc-drift micro-fixes (4 one-liners)

- **Blocked by**: none
- **Blocks**: none
- **Files**: `docs/README.md:63` ("Loaded by" → `wp-plugin` + AGENTS.md global),
  `docs/guide-pro.md:352-367` (token table gains `{theme_slug}`, `{theme-slug}`,
  `{theme_name}`), `skills/wp-theme/SKILL.md:30` (tree comment →
  "format:all:check + phpcs + phpstan gate"), `agents/scaffolder.md:17` (rename
  instruction → files/dirs containing `{plugin-slug}`/`{plugin_slug}`, slug with
  dashes)
- **Acceptance**: hub row truthful; token table covers all 11 tokens substituted by
  `setup.ps1:176-183`; wp-theme comment matches `.husky/pre-commit`; scaffolder.md
  names the tokens that actually exist in `templates/`.

## [x] T16. Guide coverage for 6 skills + /refactor

- **Blocked by**: none
- **Blocks**: none
- **Files**: `docs/guide-beginners.md` (prompt library + command table),
  `docs/guide-pro.md` if a workflow note is warranted
- **Acceptance**: `research`, `share-learning`, `tdd`, `wp-accessibility`,
  `wp-i18n`, `wp-performance` and `/refactor` each appear ≥1 time in a guide, with
  an example prompt per skill (model-invoked skills get one line each); the
  guide-reference check in `/docs-check` passes.

## [x] T17. Cross-link fix ↔ diagnosing-bugs

- **Blocked by**: T14
- **Blocks**: none
- **Files**: `skills/fix/SKILL.md`, `skills/diagnosing-bugs/SKILL.md`
- **Acceptance**: fix skill points hard/intermittent bugs to the diagnosing-bugs
  loop; diagnosing-bugs references the fix workflow for standard bugs; neither
  carries a verification-chain copy (references the canonical doc).

## [x] T18. run() helper duplication — extract or document

- **Blocked by**: T3, T5, T8
- **Blocks**: none
- **Files**: `plugins/lib/run.ts` (new), `plugins/proof-of-work.ts`,
  `plugins/phpcs-watch.ts`, `plugins/session-context.ts`, `docs/guide-pro.md` § Plugins,
  hub Plugins table, README "What's inside"
- **Acceptance**: decision taken = **extract**. `run()` + `isWin32()` moved to
  `plugins/lib/run.ts`; all three plugins import it; behavior unchanged
  (tsc strict + bun build green); docblock, hub note, guide-pro § Plugins, and
  README tree synced in the same change.

## [x] T19. Final verification gate

- **Blocked by**: all of T1-T18
- **Blocks**: none
- **Files**: none (verification only)
- **Acceptance**: `/docs-check` green (inventory, README counts, guide references,
  descriptions); `setup.ps1 -Validate` green; `opencode debug skill` +
  `opencode debug agent` show the expected set; every ticket above closed with a
  conventional commit (no AI fingerprints).
- **Correction (2026-08-05, re-audit)**: the original "prettier check green on all
  changed files" line was unverifiable — this repo has no root `.prettierrc` and
  prettier is not a dependency (prettier runs inside scaffolded projects, not here).
  The repo's formatting gate is `/docs-check` + `setup.ps1 -Validate`.

---

## Re-audit batch 2 (2026-08-05) — findings from the post-fix re-audit

## [x] T20. check.md chain copy → canonical reference

- **Blocked by**: none
- **Blocks**: none
- **Files**: `commands/check.md`
- **Acceptance**: the full 4-command copy (the 4th survivor of the dedupe) replaced
  with a reference to `docs/verification-chain.md`; repo-wide full-chain census
  returns only the gate + canonical doc + setup.ps1 UX strings.

## [x] T21. Untrack package-lock.json, standardize on bun

- **Blocked by**: none
- **Blocks**: none
- **Files**: repo root `package-lock.json`, `.gitignore`, hub map + README tree
- **Acceptance**: `package-lock.json` untracked and ignored with a bun-only comment;
  `bun.lock` stays the single lockfile; inventory already lists `package.json /
  bun.lock` (no doc change needed).

## [x] T22. Validate setup.ps1 -Name

- **Blocked by**: none
- **Blocks**: none
- **Files**: `setup.ps1`
- **Acceptance**: `-Name` rejected unless it matches `^[\w .\-]+$` — a hostile name
  (`x */ eval(...); /*`) can no longer break out of the generated plugin header
  docblock or i18n strings; valid names (`My Plugin`, `T4 Test`) unchanged.

## [x] T23. Deny branch deletion in explore agent

- **Blocked by**: none
- **Blocks**: none
- **Files**: `agents/explore.md`
- **Acceptance**: `git branch -D *` and `git branch -d *` denied after the
  `git branch*` allow in the explore agent; the read-only agent can no longer
  silently delete branches.

## [x] T24. Deny `git checkout .` in the global matrix

- **Blocked by**: none
- **Blocks**: none
- **Files**: `opencode.json`
- **Acceptance**: `"git checkout .*": "deny"` added after the `git checkout *` allow
  (last-match-wins) — the discard-all form is no longer silently allowed.

## [x] T25. Forward-slash absolute secret denies

- **Blocked by**: none
- **Blocks**: none
- **Files**: `opencode.json`
- **Acceptance**: `C:/Users/*/.ssh/**` etc. added to read + edit layers (belt-and-
  braces for the fresh-session verification of T12's backslash forms).

## [x] T26. Document the compound-command permission residual

- **Blocked by**: none
- **Blocks**: none
- **Files**: `docs/guide-pro.md` §2
- **Acceptance**: the whole-string glob trade-off (an allowed prefix matches a
  chained command) documented as a known residual with the explicit reason why
  trailing-wildcard denies are not the fix; the stale matrix rows from T2
  (`npm install*`, `bunx *`) corrected in the same pass.

## [x] T27. Traversal check before site-root resolution

- **Blocked by**: none
- **Blocks**: none
- **Files**: `setup.ps1`
- **Acceptance**: the `-Site/-Theme/-Plugin` traversal check extracted to
  `Assert-SafePathValues` and called before any `Resolve-SiteRoot`/path
  construction; rejection precedes probing; behavior unchanged otherwise.

## [x] T28. Correct T19's unverifiable prettier claim

- **Blocked by**: none
- **Blocks**: none
- **Files**: `tickets/audit-fixes.md`
- **Acceptance**: T19's record says what the repo's formatting gate actually is
  (docs-check + -Validate) instead of claiming a prettier check that cannot run
  here.

## [x] T29. Gate phpcs/phpstan steps are Windows-only

- **Blocked by**: none
- **Blocks**: none
- **Files**: `plugins/proof-of-work.ts`, `docs/guide-pro.md` §4, hub Plugins row
- **Cause**: the steps array hardcoded `vendor\\bin\\phpcs` / `vendor\\bin\\phpstan`
  (backslashes, unconditional). On POSIX `/bin/sh`, `\b` is a literal `b` →
  `vendorbinphpcs` → "command not found" — the gate could never go green
  off-Windows. The only unconditional backslash in the repo (phpcs-watch branches
  on `isWin32()`; docs, commands, opencode.json, templates all use `vendor/bin/`).
- **Acceptance**: steps array carries the canonical doc commands verbatim
  (`vendor/bin/phpcs`, `vendor/bin/phpstan` — `verify-chain-consistency.ps1` still
  green); win32 rewrites them to `vendor\bin\<tool>.bat` at exec time. Probe
  results on win32: backslash forms resolve via PATHEXT (exit 0), the forward-
  slash canonical form fails in cmd (`'vendor' is not recognized` — split at `/`),
  end-to-end gate run via bun passes all 4 steps. POSIX correctness is by
  construction (canonical form is the one every other repo file uses) — no POSIX
  machine to prove it on (fail-loud).

## [x] T30. Gate cache not scoped to target repo + git -C never triggers the gate

- **Blocked by**: none
- **Blocks**: none
- **Files**: `plugins/proof-of-work.ts`, `docs/guide-pro.md` §4, `docs/guide-advanced.md` §5
- **Cause A**: `lastGreen`/`lastState` were single-slot plugin state but `target`
  varies per call (session dir vs resolved `git -C <repo>`); two repos with
  identical `git status --porcelain` (e.g. both clean = `""`) within 120s shared a
  green cache — repo B's chain never ran.
- **Cause B** (found while testing A): `GIT_OP = /\bgit(\.exe)?\s+(push|commit)\b/`
  cannot see the verb past `git -C <path> …` — every documented multi-repo form
  returned early, ungated, and the `GIT_C` resolution branch was dead code.
- **Acceptance**: cache is a `Map` keyed by resolved target; state includes
  `git rev-parse HEAD` so a branch switch invalidates; failure deletes the
  target's entry. `GIT_OP` gains an optional `-C <path>` clause. Verified
  end-to-end via bun against two fake gated repos: `git -C` reaches the gate,
  same-repo repeat is a cache hit (no re-run), repo B with identical porcelain
  still runs, new HEAD invalidates.

---

## Re-audit batch 3 (2026-08-10) — findings from the fresh post-fix audit

## [x] T31. Plugin template: real Admin/Public classes, working settings page, shipped assets

- **Blocked by**: none
- **Blocks**: none
- **Files**: `templates/plugin/admin/class-{prefix}-admin.php`,
  `templates/plugin/public/class-{prefix}-public.php`,
  `templates/plugin/{plugin-slug}.php`, NEW
  `templates/plugin/public/css/public.css` + `public/js/public.js`
- **Cause**: the fresh 2026-08-10 audit found the plugin template's `class-` files
  contained no classes (WPCS FileName risk), the settings form posted to an
  unregistered option group (no `register_setting`), and the enqueues referenced
  assets that didn't exist in the template (fresh-scaffold 404s).
- **Acceptance**: `{Prefix}_Admin` (settings page on `admin_menu`,
  `register_setting` + section + one example field on `admin_init`,
  capability-checked render, sanitize callback) and `{Prefix}_Public` (enqueues)
  classes exist; main file instantiates both after the requires; the two asset
  files ship in the template.

## [x] T32. Plugin template gate parity + both templates' husky prepare

- **Blocked by**: none
- **Blocks**: none
- **Files**: NEW `templates/plugin/package.json` (no-op `build`, husky + prettier
  devDeps, `prepare: husky`), NEW `templates/plugin/.husky/pre-commit`,
  NEW `templates/plugin/.prettierrc`, `templates/theme/package.json` (prepare script)
- **Cause**: `isGatedProject` in `plugins/proof-of-work.ts` requires a `build`
  script, so plugin scaffolds were never gate-protected; the theme's husky hooks
  were never installed (no `prepare` script) — both templates' local gates were
  dormant.
- **Acceptance**: plugin scaffolds are gated projects (build script present — a
  documented no-op; plugins ship no compiled assets); both templates install hooks
  via `prepare: husky` on `npm install`; plugin pre-commit mirrors the theme's
  (format:all:check + phpcs + phpstan).

## [x] T33. Plugin phpstan ignore covers all constant-using files

- **Blocked by**: none
- **Blocks**: none
- **Files**: `templates/plugin/phpstan.neon`
- **Acceptance**: the `constant.notFound` ignore is no longer path-scoped to
  public/; main, includes, admin, and public files are all covered;
  `reportUnmatchedIgnoredErrors: false` already prevents unmatched-ignore noise.

## [x] T34. /context documented in both guides; template docs synced

- **Blocked by**: none
- **Blocks**: none
- **Files**: `docs/guide-beginners.md` (slash-command list + weak/strong table row),
  `docs/guide-pro.md` (delegation table row + §8 template notes), `docs/README.md`
  hub Plugin row
- **Cause**: `/context` was the only command absent from both guides (hub-only);
  the hub Plugin row and §8 didn't reflect the batch-3 template changes.
- **Acceptance**: `/context` appears in guide-beginners and guide-pro; hub Plugin
  row describes the working settings page, shipped assets, and pre-commit gate;
  §8 documents the no-op build rationale and the `prepare: husky` wiring;
  `/docs-check` green.
