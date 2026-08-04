#requires -Version 5.1
<#
.SYNOPSIS
	Snoozle OpenCode WordPress settings - validation and project scaffolding.

.DESCRIPTION
	This repo IS the global OpenCode config (~/.config/opencode), so there is
	nothing to install. This script:

	  * Default (-Validate):   checks skill/agent/command frontmatter and structure.
	  * -NewTheme:             scaffolds a new classic theme project from templates/theme.
	  * -NewPlugin:            scaffolds a new plugin project from templates/plugin.

.PARAMETER Validate
	Run structural validation only (default).

.PARAMETER NewTheme
	Target directory for a new theme project.

.PARAMETER NewPlugin
	Target directory for a new plugin project.

.PARAMETER Slug
	Project slug (folder name + text domain, dashes allowed). Default: folder name.

.PARAMETER Prefix
	Function/class prefix (e.g. "ss_"). Default: first 4 letters of slug + "_".

.PARAMETER Name
	Human-readable project name. Default: slug title-cased.

.PARAMETER DryRun
	Report what would be done without writing.

.EXAMPLE
	.\setup.ps1 -Validate
	.\setup.ps1 -NewTheme ..\wp-content\themes\ss -Slug ss -Prefix ss_ -Name "Snoozle Studio"
	.\setup.ps1 -NewPlugin .\my-plugin -Slug my-plugin -Prefix myp_ -Name "My Plugin"
#>

param(
	[switch]$Validate,
	[string]$NewTheme,
	[string]$NewPlugin,
	[string]$Slug = "",
	[string]$Prefix = "",
	[string]$Name = "",
	[switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step([string]$Message) { Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "    $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "    WARN: $Message" -ForegroundColor Yellow }
function Write-Fail([string]$Message) { Write-Host "    FAIL: $Message" -ForegroundColor Red }

function Test-Frontmatter([string]$File, [string]$Kind, [string]$DirName) {
	$content = Get-Content -LiteralPath $File -Raw -ErrorAction SilentlyContinue
	if (-not $content) { Write-Fail "${Kind} $File is empty or unreadable"; return $false }
	if ($content -notmatch '^---\r?\n') { Write-Fail "${Kind} $File has no frontmatter"; return $false }
	if ($content -notmatch '(?m)^description:\s*.+') { Write-Fail "${Kind} $File has no description"; return $false }
	if ($Kind -eq "skill" -and $content -notmatch "(?m)^name:\s*$([regex]::Escape($DirName))\s*$") {
		Write-Fail "skill ${File}: frontmatter name must match directory name '$DirName'"
		return $false
	}
	Write-Ok "${Kind}: $(Split-Path $File -Leaf)"
	return $true
}

function Invoke-Validate {
	Write-Step "Validating repo structure"
	$failed = $false

	if (-not (Test-Path "$RepoRoot\AGENTS.md")) { Write-Fail "AGENTS.md missing"; $failed = $true }
	if (-not (Test-Path "$RepoRoot\opencode.json")) { Write-Fail "opencode.json missing"; $failed = $true }

	foreach ($file in Get-ChildItem "$RepoRoot\agents" -Filter *.md -ErrorAction SilentlyContinue) {
		if (-not (Test-Frontmatter $file.FullName "agent" "")) { $failed = $true }
	}
	foreach ($dir in Get-ChildItem "$RepoRoot\skills" -Directory -ErrorAction SilentlyContinue) {
		$skill = Join-Path $dir.FullName "SKILL.md"
		if (-not (Test-Path $skill)) { Write-Fail "skill $($dir.Name) has no SKILL.md"; $failed = $true; continue }
		if (-not (Test-Frontmatter $skill "skill" $dir.Name)) { $failed = $true }
	}
	foreach ($file in Get-ChildItem "$RepoRoot\commands" -Filter *.md -ErrorAction SilentlyContinue) {
		if (-not (Test-Frontmatter $file.FullName "command" "")) { $failed = $true }
	}

	if ($failed) { Write-Host ""; Write-Host "Validation FAILED - fix before committing." -ForegroundColor Red; exit 1 }
	Write-Host ""
	Write-Host "Validation OK." -ForegroundColor Green
}

function Expand-Template([string]$Source, [string]$Destination, [hashtable]$Tokens) {
	Write-Step "Scaffolding from $Source"
	$items = Get-ChildItem -LiteralPath $Source -Recurse -Force
	foreach ($item in $items) {
		$relative = $item.FullName.Substring($Source.Length).TrimStart("\")
		foreach ($key in $Tokens.Keys) {
			$relative = $relative.Replace($key, $Tokens[$key])
		}
		$dest = Join-Path $Destination $relative
		if ($item.PSIsContainer) {
			if (-not $DryRun) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
			continue
		}
		if ($DryRun) { Write-Ok "would write $relative"; continue }
		New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
		$content = Get-Content -LiteralPath $item.FullName -Raw
		foreach ($key in $Tokens.Keys) {
			$content = $content.Replace($key, $Tokens[$key])
		}
		Set-Content -LiteralPath $dest -Value $content -Encoding UTF8 -NoNewline
		$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
		[System.IO.File]::WriteAllText($dest, $content, $utf8NoBom)
		Write-Ok "wrote $relative"
	}
}

function Resolve-Args([string]$Target, [string]$Kind) {
	if (-not $Target) { throw "Missing target directory (use -NewTheme or -NewPlugin)." }
	$script:Target = $Target
	if (-not $Slug) { $script:Slug = Split-Path $Target -Leaf }
	if (-not $Prefix) {
		$letters = ($Slug -replace '-', '')
		$script:Prefix = $letters.Substring(0, [Math]::Min(4, $letters.Length)) + "_"
	}
	if (-not $Name) { $script:Name = (Get-Culture).TextInfo.ToTitleCase(($Slug -replace '-', ' ')) }

	# The prefix token carries no trailing underscore: templates use
	# {prefix}_function_name, so prefix "tst_" yields "tst_function_name".
	$base = $Prefix.TrimEnd("_")
	$script:Tokens = New-Object "System.Collections.Generic.Dictionary[string,string]"
	$script:Tokens.Add(("{" + $Kind + "_slug}"), $Slug)
	$script:Tokens.Add(("{" + $Kind + "-slug}"), $Slug)
	$script:Tokens.Add(("{" + $Kind + "_name}"), $Name)
	$script:Tokens.Add("{text_domain}", $Slug)
	$script:Tokens.Add("{prefix}", $base)
	$script:Tokens.Add("{PREFIX}", $base.ToUpper())
	$script:Tokens.Add("{Prefix}", ($base.Substring(0, 1).ToUpper() + $base.Substring(1)))
	$script:Tokens.Add("{description}", "Initial description.")
	Write-Ok "slug=$Slug prefix=$Prefix name=$Name text-domain=$Slug"
}

if ($Validate -or (-not $NewTheme -and -not $NewPlugin)) {
	Invoke-Validate
	exit 0
}

if ($NewTheme) {
	Resolve-Args $NewTheme "theme"
	New-Item -ItemType Directory -Path $NewTheme -Force | Out-Null
	Expand-Template "$RepoRoot\templates\theme" (Resolve-Path $NewTheme) $Tokens
}
if ($NewPlugin) {
	Resolve-Args $NewPlugin "plugin"
	New-Item -ItemType Directory -Path $NewPlugin -Force | Out-Null
	Expand-Template "$RepoRoot\templates\plugin" (Resolve-Path $NewPlugin) $Tokens
}

if (-not $DryRun) {
	Write-Step "Next steps"
	Write-Host "  1. cd $Target"
	Write-Host "  2. npm install"
	Write-Host "  3. composer install"
	Write-Host "  4. Edit style.css/readme.txt metadata and ACF field groups"
	Write-Host "  5. Run: npm run build / npm run format:all:check / vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M"
}
