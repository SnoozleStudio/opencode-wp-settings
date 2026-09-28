# Help + Matrix — Tickets

Follow-ups from the cross-platform hardening (2026-09-28): a `Get-Help`
discovery and the Linux/Apple machine-proof.

---

## [x] T60. Fix `Get-Help -Parameter` on PowerShell 5.1

- **Blocked by**: none
- **Blocks**: none
- **Files**: `setup.ps1` (comment/help ordering only)
- **Cause**: `#requires -Version 5.1` on line 1 broke `.PARAMETER` association
  in 5.1 — `(Get-Help .\setup.ps1).parameters` was empty while syntax rendered
  from the AST. Proven by minimal probes: help without `#requires` parses,
  with `#requires` first it does not. (The blank line between `#>` and
  `param(` was tested first and ruled out.)
- **Acceptance**: `#requires` moved below the help block (still before all
  code — honored identically); all 14 params incl. `-WpRoot` resolve via
  `Get-Help -Parameter` on 5.1; `-Validate` green.
- **Recorded deviations**: none.

## [x] T61. Machine-proof macOS in CI (Apple) + keep Linux green

- **Blocked by**: none
- **Blocks**: none
- **Files**: `.github/workflows/ci.yml` (new `macos` job), `README.md`
  (checks badge 6 → 7, quality list), `docs/guide-pro.md` (§10)
- **Cause**: CI ran `ubuntu-latest` only — macOS was correct-by-construction,
  never machine-proven. There is no local Mac/Linux here; GitHub runners are
  the honest proof for both Apple (`macos-latest`) and Linux (`ubuntu-latest`,
  already covered).
- **Acceptance**: `macos` job mirrors structure (`-Validate`, `sh -n`,
  `scaffold.sh -Validate`) + smoke (theme/plugin/any-stack dry-runs) with the
  same SHA pins; `docs-inventory.ps1` badge check passes at 7; zizmor +
  actionlint clean; Linux jobs untouched and green.
- **Recorded deviations**: remote proof lands on push (CI triggers on
  push/PR) — local run of the identical steps is the interim evidence.
