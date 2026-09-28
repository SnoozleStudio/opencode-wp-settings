# Stack-Neutral Scaffolding — Tickets

Tracer-bullet tickets for decoupling `setup.ps1` scaffolding from Local
(2026-09-28, user decision: auto-detect layout, neutral wording, keep
`-Site`/`-SitesDir` names). `Resolve-WpRoot` was already stack-neutral;
`Invoke-ProjectInstall` already ran plain installs off Local PHP. Only the
named-site path and the wording assumed Local.

## Execution order

1. **Wave A:** T50, T51, T52 (all `setup.ps1`, sequential — same file)
2. **Wave B:** T53 (docs, after Wave A wording settles)
3. **Wave C:** T54 (verification + CI smoke), after everything else

---

## [x] T50. Auto-detect site layout in named-site resolution

- **Blocked by**: none
- **Blocks**: T54
- **Files**: `setup.ps1` (`Resolve-LocalSiteRoot` → `Resolve-NamedSiteRoot`)
- **Acceptance**: `<sites>/<name>/wp-load.php` tried first (XAMPP/MAMP/plain),
  `<sites>/<name>/app/public` fallback (Local); missing names still list
  available sites; proven by dry-runs against fake plain + Local trees.
- **Recorded deviations**: none.

## [x] T51. `-WpRoot` explicit-root parameter

- **Blocked by**: none
- **Blocks**: T54
- **Files**: `setup.ps1` (param block, `Resolve-SiteRoot` precedence)
- **Acceptance**: `-WpRoot` wins over walk-up and `-Site`; non-roots rejected
  with a clear error; proven by positive + negative dry-runs.
- **Recorded deviations**: none.

## [x] T52. Stack-neutral help, examples, and install messages

- **Blocked by**: none
- **Blocks**: T53
- **Files**: `setup.ps1` (header, `.PARAMETER`, `.EXAMPLE`, install output)
- **Acceptance**: no Local-only claims in help; `-Site`/`-SitesDir` names kept
  (param contract unbroken); `lightning-services` detection kept, messages
  generic ("bundled PHP" / "system PHP").
- **Recorded deviations**: none.

## [x] T53. Docs sync (README, hub, guide-pro)

- **Blocked by**: T52
- **Blocks**: T54
- **Files**: `README.md` (scaffolding section), `docs/README.md` (Scripts table),
  `docs/guide-pro.md` (§ Scaffolding table + root-resolution section)
- **Acceptance**: XAMPP/MAMP/Linux/Docker framed as first-class, Local as one
  flavor; `-WpRoot` + layout auto-detect documented; `/docs-check` mechanical
  subset (`docs-inventory.ps1`) green.
- **Recorded deviations**: none.

## [x] T54. Final verification gate

- **Blocked by**: T50-T53
- **Blocks**: none
- **Files**: `.github/workflows/ci.yml` (smoke), none otherwise
- **Acceptance**: `-Validate`, `docs-inventory`, `verify-chain-consistency`
  green; dry-runs green for all four resolutions (walk-up, plain `-Site`,
  Local-layout `-Site`, `-WpRoot`) + both negatives (bad `-WpRoot`, unknown
  `-Site`); CI smoke gains fake-root `-WpRoot` + plain `-Site` dry-runs
  (POSIX proof on ubuntu); zizmor + actionlint 1.7.12/1.30.1 clean;
  `git status` shows only intended files.
- **Recorded deviations**: `Get-Help -Parameter` lookup fails for ALL params
  (incl. pre-existing `-Site`) on PowerShell 5.1 — pre-existing quirk, not a
  regression; function proven by dry-runs instead.
