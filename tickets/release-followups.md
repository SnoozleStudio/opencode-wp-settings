# Release Follow-ups — Tickets

Tracer-bullet tickets for the 6 low-severity findings deferred at the v1.1.0
release audit (2026-09-28, released tag-as-is per user decision). All findings
were verified read-only before ticketing (3 subagent passes: docs drift,
security surface, structure/CI). Every ticket touches THIS repo, so the
documentation contract applies: docs sync in the same change as the code.

## Execution order

1. **Wave A (parallel — distinct files):** T35 (plugins/proof-of-work.ts),
   T36 (opencode.json + guide-pro §2), T37 (agents/explore.md), T38 (both
   template composer.json), T39 (ci.yml)
2. **Wave B:** T40 (final verification), after everything else

---

## [x] T35. Tolerate interposed git flags in GIT_OP/GIT_C + Push-Location in DIR_CHANGE

- **Blocked by**: none
- **Blocks**: T40
- **Files**: `plugins/proof-of-work.ts` (regexes + docblocks),
  `docs/guide-pro.md` §4 Scope bullet (Push-Location wording)
- **Cause**: `GIT_OP` requires `git [-C <path>] <push|commit>` with nothing in
  between, so `git --no-pager commit`, `git -c core.hooksPath=… commit`, or
  `git -C <repo> --no-pager commit` returns early and never reaches the gate
  (accidental-skip path, same one-line class as the T30 `-C` fix — not a
  privilege boundary, the gate is best-effort UX with a documented
  `--no-verify` escape). `DIR_CHANGE` covers `cd`/`Set-Location`/`pushd` but
  not the full `Push-Location` cmdlet, so `Push-Location <other>; git commit`
  gates the wrong (session) directory.
- **Acceptance**: `GIT_OP`/`GIT_C` carry a lazy interposed-flags fragment
  `(?:\s+-[^\s;&|]+(?:\s+[^\s;&|]+)?)*?` (flags never swallow `;`/`&`/`|`
  chains); `git --no-pager commit`, `git -c k=v commit`, and
  `git -C <repo> --no-pager commit` all trigger the gate with the `-C` target
  still resolved; `Push-Location` added to `DIR_CHANGE`; docblocks + guide-pro
  §4 Scope bullet name all four directory-change forms; `tsc --noEmit --strict`
  + `bun build` green; behavior matrix probed end-to-end (trigger + target).
- **Recorded deviations**: none.

## [x] T36. Deny lowercase `git branch -d` in the global matrix

- **Blocked by**: none
- **Blocks**: T40
- **Files**: `opencode.json`, `docs/guide-pro.md` §2 permission table (deny row)
- **Cause**: the global matrix denies `git branch -D *` but not lowercase
  `git branch -d *` (safe-delete still deletes), while `agents/explore.md`
  already denies both (T23 fixed it agent-locally only).
- **Acceptance**: `"git branch -d *": "deny"` added after the `-D` deny
  (last-match-wins preserved); guide-pro §2 deny row names both forms;
  `setup.ps1 -Validate` green.
- **Recorded deviations**: none.

## [x] T37. Drop `Select-String*` from the explore allowlist

- **Blocked by**: none
- **Blocks**: T40
- **Files**: `agents/explore.md`
- **Cause**: `Select-String*` is auto-allowed in explore scope but the
  secret-deny lists only cover `cat`/`type`/`Get-Content`, so
  `Select-String password C:\…\.ssh\…` lands secret material in context
  without a prompt. `security-auditor.md` never had the allow — removal aligns
  the two read-only agents.
- **Acceptance**: the `Select-String*` allow line deleted (falls back to
  `"*": "ask"`); `rg`/`grep`/`Get-ChildItem` discovery flows unchanged;
  `setup.ps1 -Validate` green (frontmatter untouched).
- **Recorded deviations**: no doc sync — description frontmatter and hub Agents
  row describe the role (unchanged), and no doc names `Select-String`.

## [x] T38. Require the composer installer plugin in both template composer.json

- **Blocked by**: none
- **Blocks**: T40
- **Files**: `templates/theme/composer.json`, `templates/plugin/composer.json`
- **Cause**: both templates set
  `config.allow-plugins.dealerdirect/phpcodesniffer-composer-installer: true`
  but never `require` the package, so a fresh scaffold's `composer install`
  never installs the installer plugin and WPCS path registration may not run.
  Latest verified via Packagist 2026-09-28: v1.2.1 (no v3 line exists).
- **Acceptance**: `"dealerdirect/phpcodesniffer-composer-installer": "^1.0"`
  first in `require-dev` (alphabetical) in both templates; both scaffold
  dry-runs (`-NewTheme`/`-NewPlugin -DryRun`, incl. JSON validation) green.
- **Recorded deviations**: no doc sync — the hub External-libraries Composer
  table (`docs/README.md:267`) already cites the package; flow/wording
  unchanged (dependency-only addition).

## [x] T39. Harden the CI JSON job against tui.jsonc comments

- **Blocked by**: none
- **Blocks**: T40
- **Files**: `.github/workflows/ci.yml`
- **Cause**: the `json` job runs `jq empty` over `tui.jsonc`, which passes today
  only because the file is comment-free valid JSON — the first `//` comment
  anyone adds reds the gate.
- **Acceptance**: strict files keep `jq empty`; `tui.jsonc` is validated after
  stripping full-line `//` comments
  (`sed -e 's/^[[:space:]]*\/\/.*$//'` — full-line only, so inline `https://`
  URLs survive); the step documents the residual (block comments / trailing
  commas still fail — fail-loud, add a real JSONC parser if ever needed);
  actionlint + zizmor green.
- **Recorded deviations**: no doc sync — same jobs, same files, behavior-
  preserving hardening (contract rows describe the CI at job level).

## [x] T40. Final verification gate

- **Blocked by**: T35-T39
- **Blocks**: none
- **Files**: none (verification only)
- **Acceptance**: `setup.ps1 -Validate` green; `scripts/docs-inventory.ps1`
  green; `scripts/verify-chain-consistency.ps1` green; `tsc --noEmit --strict`
  + `bun build` on the touched plugins green; both template dry-runs green;
  every ticket above closed; `git status` shows only intended files.
- **Recorded deviations**: none.
