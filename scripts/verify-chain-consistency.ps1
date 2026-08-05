#requires -Version 5.1
<#
.SYNOPSIS
	Verifies the proof-of-work chain is not duplicated: the commands in
	docs/verification-chain.md (the single source of truth) must match the steps
	hardcoded in plugins/proof-of-work.ts. Exit 1 on drift.

.DESCRIPTION
	The chain is defined once in docs/verification-chain.md; the gate plugin
	carries an implementation copy it must not silently diverge from. This script
	extracts both, normalizes (backslashes to slashes, strips inline comments and
	whitespace), and compares them as ordered lists. Add a CI step instead of
	inlining the chain anywhere else.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$failures = New-Object System.Collections.Generic.List[string]

function Get-DocChainCommands {
	$doc = Get-Content -LiteralPath (Join-Path $RepoRoot "docs\verification-chain.md") -Raw
	$m = [regex]::Match($doc, '(?ms)```text\r?\n(.*?)```')
	if (-not $m.Success) {
		throw 'docs/verification-chain.md: no ```text code block found'
	}
	$commands = @()
	foreach ($line in ($m.Groups[1].Value -split "\r?\n")) {
		$clean = ($line -split "#")[0].Trim()
		if ($clean -eq "") { continue }
		$commands += $clean.Replace("\", "/")
	}
	return $commands
}

function Get-PluginChainCommands {
	$plugin = Get-Content -LiteralPath (Join-Path $RepoRoot "plugins\proof-of-work.ts") -Raw
	$commands = @()
	foreach ($mm in [regex]::Matches($plugin, '\[\s*"[A-Za-z][\w:]*"\s*,\s*"([^"]+)"\s*,?\s*\]')) {
		$commands += $mm.Groups[1].Value.Replace("\\", "/").Replace("\", "/").Trim()
	}
	if ($commands.Count -eq 0) {
		throw "plugins/proof-of-work.ts: no chain steps array found"
	}
	return $commands
}

Write-Host "==> Verification-chain consistency check" -ForegroundColor Cyan

$doc = Get-DocChainCommands
$plugin = Get-PluginChainCommands

if ($doc.Count -ne $plugin.Count) {
	$failures.Add("chain: docs/verification-chain.md has $($doc.Count) step(s), plugins/proof-of-work.ts has $($plugin.Count)")
} else {
	for ($i = 0; $i -lt $doc.Count; $i++) {
		if ($doc[$i] -ne $plugin[$i]) {
			$failures.Add("chain: step $($i + 1) mismatch - docs: '$($doc[$i])' vs plugin: '$($plugin[$i])'")
		}
	}
}

if ($failures.Count -gt 0) {
	foreach ($f in $failures) { Write-Host "    FAIL: $f" -ForegroundColor Red }
	Write-Host ""
	Write-Host "Chain consistency FAILED ($($failures.Count) finding(s)). Update docs/verification-chain.md and plugins/proof-of-work.ts together." -ForegroundColor Red
	exit 1
}
Write-Host "    Chain consistency OK ($($doc.Count) steps, docs and plugin in sync)." -ForegroundColor Green
exit 0
