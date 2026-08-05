#requires -Version 5.1
<#
.SYNOPSIS
	Deterministic docs-inventory check: hub inventory vs filesystem, component
	counts, and internal markdown links. Used by CI and locally before commits.

.DESCRIPTION
	Ports the mechanical subset of the /docs-check command to a script that runs
	without an agent:

	  1. Inventory both directions - every agent/skill/command/plugin/template/
	     script/CI-workflow listed in docs/README.md must exist on disk, and
	     every such file on disk must be listed in docs/README.md.
	  2. Counts - docs/README.md section headers and README.md "What's inside"
	     counts must match the actual filesystem.
	  3. Internal links - every relative markdown link in every *.md file
	     (outside node_modules/ and .git/) must resolve to an existing path.

	Semantic checks (description wording, guide references by name, drift
	reasoning) remain with the agent-based /docs-check command.

	Exits 1 on any drift. Report format mirrors setup.ps1: FAIL lines, then a
	summary.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$HubPath = Join-Path $RepoRoot "docs\README.md"
$ReadmePath = Join-Path $RepoRoot "README.md"
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$Message) { $failures.Add($Message) }

function Get-RelativePart([string]$Target) {
	# Strip markdown link decorations: angle brackets, fragment, query.
	$t = $Target.Trim().TrimStart("<").TrimEnd(">")
	$t = ($t -split "#")[0]
	$t = ($t -split "\?")[0]
	return $t.Trim()
}

function Get-LinkTargets([string]$Content) {
	$targets = @()
	foreach ($m in [regex]::Matches($Content, '\[[^\]]*\]\(([^)]+)\)')) {
		$targets += $m.Groups[1].Value
	}
	return $targets
}

function Get-HubItems([string]$Prefix) {
	$content = Get-Content -LiteralPath $HubPath -Raw
	$items = @()
	$needle = "../" + $Prefix + "/"
	foreach ($t in (Get-LinkTargets $content)) {
		$part = Get-RelativePart $t
		if ($part.StartsWith($needle, [System.StringComparison]::OrdinalIgnoreCase)) {
			$items += $part.Substring($needle.Length)
		}
	}
	return $items
}

function Assert-SetMatch {
	param(
		[string]$Kind,
		[string[]]$FsItems,
		[string[]]$HubItems,
		[string]$FsLabel,
		[string]$HubLabel
	)
	foreach ($i in ($FsItems | Sort-Object)) {
		if ($HubItems -notcontains $i) {
			Add-Failure "inventory: $Kind '$FsLabel\$i' exists on disk but is not listed in docs/README.md"
		}
	}
	foreach ($i in ($HubItems | Sort-Object)) {
		if ($FsItems -notcontains $i) {
			Add-Failure "inventory: $Kind '$HubLabel\$i' is listed in docs/README.md but missing on disk"
		}
	}
}

function Assert-LinksResolve([string]$File) {
	$inFence = $false
	$lineNo = 0
	foreach ($line in (Get-Content -LiteralPath $File)) {
		$lineNo++
		if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
		if ($inFence) { continue }
		$clean = $line -replace '`[^`]*`', ""
		foreach ($m in [regex]::Matches($clean, '\[[^\]]*\]\(([^)]+)\)')) {
			$target = Get-RelativePart $m.Groups[1].Value
			if ($target -eq "") { continue }
			if ($target -match '^(https?:|mailto:|tel:|data:)') { continue }
			if ($target.StartsWith("#") -or $target.StartsWith("/")) { continue }
			$resolved = [System.IO.Path]::GetFullPath((Join-Path (Split-Path $File -Parent) $target))
			if (-not (Test-Path -LiteralPath $resolved)) {
				$short = $File.Replace($RepoRoot + [System.IO.Path]::DirectorySeparatorChar, "")
				Add-Failure "link: $short line ${lineNo}: '$target' does not resolve"
			}
		}
	}
}

Write-Host "==> Docs inventory check" -ForegroundColor Cyan

# --- 1. Inventory vs filesystem (both directions) ---
$agents = @(Get-ChildItem (Join-Path $RepoRoot "agents") -Filter *.md -File | ForEach-Object { $_.Name })
Assert-SetMatch "agent" $agents @(Get-HubItems "agents") "agents" "agents"

$commands = @(Get-ChildItem (Join-Path $RepoRoot "commands") -Filter *.md -File | ForEach-Object { $_.Name })
Assert-SetMatch "command" $commands @(Get-HubItems "commands") "commands" "commands"

$pluginRoot = Join-Path $RepoRoot "plugins"
$plugins = @(Get-ChildItem $pluginRoot -Recurse -File | ForEach-Object {
	$_.FullName.Substring($pluginRoot.Length + 1).Replace("\", "/")
})
Assert-SetMatch "plugin" $plugins @(Get-HubItems "plugins") "plugins" "plugins"

$skillRoot = Join-Path $RepoRoot "skills"
$skills = @(Get-ChildItem $skillRoot -Directory | ForEach-Object { $_.Name })
$skillHub = @(Get-HubItems "skills" | ForEach-Object { ($_ -split "/")[0] })
Assert-SetMatch "skill" $skills $skillHub "skills" "skills"

$templateRoot = Join-Path $RepoRoot "templates"
$templates = @(Get-ChildItem $templateRoot -Directory | ForEach-Object { $_.Name })
$templateHub = @(Get-HubItems "templates" | ForEach-Object { ($_ -split "/")[0] })
Assert-SetMatch "template" $templates $templateHub "templates" "templates"

$scriptRoot = Join-Path $RepoRoot "scripts"
$scripts = @(Get-ChildItem $scriptRoot -Recurse -File | ForEach-Object {
	$_.FullName.Substring($scriptRoot.Length + 1).Replace("\", "/")
})
Assert-SetMatch "script" $scripts @(Get-HubItems "scripts") "scripts" "scripts"

$wfRoot = Join-Path $RepoRoot ".github\workflows"
if (Test-Path $wfRoot) {
	$wf = @(Get-ChildItem $wfRoot -File | ForEach-Object { $_.Name })
	Assert-SetMatch "CI workflow" $wf @(Get-HubItems ".github/workflows") ".github/workflows" ".github/workflows"
}

# --- 2. Counts ---
# "plugins" counts the hook plugins (root .ts files); lib/run.ts is the shared
# shell helper, listed in the hub but not counted as a plugin.
$counts = @{
	"agents"    = $agents.Count
	"skills"    = $skills.Count
	"commands"  = $commands.Count
	"plugins"   = @(Get-ChildItem $pluginRoot -Filter *.ts -File).Count
	"templates" = $templates.Count
}

$hubContent = Get-Content -LiteralPath $HubPath -Raw
foreach ($k in @("agents", "skills", "commands", "plugins", "templates")) {
	$title = $k.Substring(0, 1).ToUpper() + $k.Substring(1)
	$m = [regex]::Match($hubContent, "### " + $title + " \((\d+)\)")
	if (-not $m.Success) {
		Add-Failure "count: docs/README.md has no '### $title (N)' header"
		continue
	}
	if ([int]$m.Groups[1].Value -ne $counts[$k]) {
		Add-Failure "count: docs/README.md header '$title ($($m.Groups[1].Value))' != actual $($counts[$k])"
	}
}

$readmeContent = Get-Content -LiteralPath $ReadmePath -Raw
$patterns = @{
	"agents"    = "agents/\s+(\d+) subagents"
	"skills"    = "skills/\s+(\d+) skills"
	"commands"  = "commands/\s+(\d+) slash commands"
	"plugins"   = "plugins/\s+(\d+) hook plugins"
}
foreach ($k in $patterns.Keys) {
	$m = [regex]::Match($readmeContent, $patterns[$k])
	if (-not $m.Success) {
		Add-Failure "count: README.md 'What's inside' has no count line for $k"
		continue
	}
	if ([int]$m.Groups[1].Value -ne $counts[$k]) {
		Add-Failure "count: README.md says $k = $($m.Groups[1].Value), actual $($counts[$k])"
	}
}

# --- 2b. Checks badge is measured: the count must match the CI jobs ---
$wfPath = Join-Path $RepoRoot ".github\workflows\ci.yml"
if (Test-Path $wfPath) {
	$wfContent = Get-Content -LiteralPath $wfPath -Raw
	$jobsSection = ""
	if ($wfContent -match "(?ms)^jobs:\r?\n(.*?)(?=^\S|\z)") { $jobsSection = $Matches[1] }
	$jobCount = @([regex]::Matches($jobsSection, '(?m)^  [a-z0-9_-]+:$')).Count
	$badge = [regex]::Match($readmeContent, 'img\.shields\.io/badge/checks-(\d+)')
	if (-not $badge.Success) {
		Add-Failure "count: README.md has no checks badge (img.shields.io/badge/checks-N)"
	} elseif ([int]$badge.Groups[1].Value -ne $jobCount) {
		Add-Failure "count: README.md checks badge says $($badge.Groups[1].Value) but .github/workflows/ci.yml has $jobCount job(s)"
	}
}

# --- 3. Internal markdown links ---
$mdFiles = @()
foreach ($dir in (Get-ChildItem -LiteralPath $RepoRoot -Directory -Recurse | Where-Object {
	$_.FullName -notmatch "(^|[\\/])node_modules([\\/]|$)" -and $_.FullName -notmatch "(^|[\\/])\.git([\\/]|$)"
})) {
	$mdFiles += @(Get-ChildItem -LiteralPath $dir.FullName -Filter *.md -File)
}
$mdFiles += @(Get-ChildItem -LiteralPath $RepoRoot -Filter *.md -File)

foreach ($f in $mdFiles) { Assert-LinksResolve $f.FullName }

# --- Summary ---
if ($failures.Count -gt 0) {
	foreach ($f in $failures) { Write-Host "    FAIL: $f" -ForegroundColor Red }
	Write-Host ""
	Write-Host "Docs inventory FAILED ($($failures.Count) finding(s))." -ForegroundColor Red
	exit 1
}
Write-Host "    Docs inventory OK (inventory, counts, links)." -ForegroundColor Green
exit 0
