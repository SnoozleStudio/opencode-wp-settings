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

## T14. Canonicalize the verification chain

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
  remain repo-wide (the gate + the canonical doc + README diagram); all others
  reference the doc; `/docs-check` green.

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

## T17. Cross-link fix ↔ diagnosing-bugs

- **Blocked by**: T14
- **Blocks**: none
- **Files**: `skills/fix/SKILL.md`, `skills/diagnosing-bugs/SKILL.md`
- **Acceptance**: fix skill points hard/intermittent bugs to the diagnosing-bugs
  loop; diagnosing-bugs references the fix workflow for standard bugs; neither
  carries a verification-chain copy (references the canonical doc).

## T18. run() helper duplication — extract or document

- **Blocked by**: T3, T5, T8
- **Blocks**: none
- **Files**: `plugins/proof-of-work.ts`, `plugins/phpcs-watch.ts`,
  `plugins/session-context.ts` (+ `plugins/lib/run.ts` if extraction), `docs/guide-pro.md` § Plugins
- **Acceptance**: EITHER the ~20-line `run()`/`execFileAsync` wrapper extracted to a
  shared module imported by all three plugins with no behavior change, OR an
  explicit "plugin isolation is intentional — each plugin is self-contained"
  note in guide-pro § Plugins. No silent third option.

## T19. Final verification gate

- **Blocked by**: all of T1-T18
- **Blocks**: none
- **Files**: none (verification only)
- **Acceptance**: `/docs-check` green (inventory, README counts, guide references,
  descriptions); `setup.ps1 -Validate` green; prettier check green on all changed
  files; `opencode debug skill` + `opencode debug agent` show the expected set;
  every ticket above closed with a conventional commit (no AI fingerprints).
