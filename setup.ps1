#requires -Version 5.1
<#
.SYNOPSIS
	Snoozle OpenCode WordPress settings - validation and project scaffolding.

.DESCRIPTION
	This repo IS the global OpenCode config (~/.config/opencode), so there is
	nothing to install. This script:

	  * Default (-Validate):     checks skill/agent/command frontmatter and structure.
	  * -NewTheme/-NewPlugin:    scaffolds into an explicit target directory.
	  * -Theme/-Plugin:          scaffolds into wp-content\themes|plugins\{slug} of the
	                             current WordPress root (Local site shell) or of -Site.

.PARAMETER Validate
	Run structural validation only (default).

.PARAMETER NewTheme
	Target directory for a new theme project (explicit path).

.PARAMETER NewPlugin
	Target directory for a new plugin project (explicit path).

.PARAMETER Theme
	Slug for a theme scaffolded into wp-content\themes\{slug}. The WordPress root is
	resolved by walking up from the current directory (Local's site shell starts in
	<site>\app\public, a WordPress root) or from -Site.

.PARAMETER Plugin
	Slug for a plugin scaffolded into wp-content\plugins\{slug}. Same root resolution.

.PARAMETER Site
	Local site name; root resolves to {SitesDir}\{site}\app\public. Not needed when the
	current directory is already inside a WordPress root.

.PARAMETER SitesDir
	Local sites directory (default: $HOME\Local Sites). Only used with -Site.

.PARAMETER Install
	After scaffolding, run npm install and composer install in the new project. When
	the PHP on PATH is Local's bundled build (lightning-services), a temp php.ini with
	openssl + mbstring enabled is used via PHPRC - Local ships both disabled.

.PARAMETER Force
	Allow scaffolding into an existing non-empty target directory (files are merged;
	existing files are overwritten, extra files are kept).

.PARAMETER Slug
	Project slug (folder name + text domain, dashes allowed). Default: target folder
	name (for -Theme/-Plugin: the slug itself).

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
	# From Local's site shell (cmd.exe by default on Windows - use scaffold.cmd):
	scaffold.cmd -Theme mytheme -Prefix mt_ -Name "My Theme"
	scaffold.cmd -Plugin my-plugin -Install
	# From Local's site shell configured to PowerShell:
	.\setup.ps1 -Theme mytheme -Prefix mt_ -Name "My Theme"
	# From anywhere, targeting a site by name:
	.\setup.ps1 -Site mysite -Theme mytheme -Install
	.\setup.ps1 -Theme demo -SitesDir D:\Local\Sites -DryRun
#>

param(
	[switch]$Validate,
	[string]$NewTheme,
	[string]$NewPlugin,
	[string]$Theme,
	[string]$Plugin,
	[string]$Site,
	[string]$SitesDir,
	[switch]$Install,
	[switch]$Force,
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
	if (-not $Target) { throw "Missing target directory (use -NewTheme, -NewPlugin, -Theme or -Plugin)." }
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

function Resolve-WpRoot {
	# Walk up from the current directory until wp-load.php is found (WordPress root).
	$dir = Get-Item (Get-Location).Path
	while ($dir) {
		if (Test-Path (Join-Path $dir.FullName "wp-load.php")) { return $dir.FullName }
		$dir = $dir.Parent
	}
	return $null
}

function Resolve-LocalSiteRoot([string]$SiteName) {
	$sitesRoot = if ($SitesDir) { $SitesDir } else { Join-Path $HOME "Local Sites" }
	if (-not (Test-Path -LiteralPath $sitesRoot)) {
		throw "Local sites directory not found: $sitesRoot (pass -SitesDir to override)."
	}
	$siteDir = Join-Path $sitesRoot $SiteName
	if (-not (Test-Path -LiteralPath $siteDir)) {
		$available = ((Get-ChildItem -LiteralPath $sitesRoot -Directory -ErrorAction SilentlyContinue).Name) -join ", "
		throw "Local site '$SiteName' not found in $sitesRoot. Available sites: $available"
	}
	$public = Join-Path $siteDir "app\public"
	if (-not (Test-Path (Join-Path $public "wp-load.php"))) {
		throw "Site '$SiteName' root not found at $public (expected app\public containing wp-load.php)."
	}
	Write-Ok "Local site '$SiteName' root: $public"
	return $public
}

function Resolve-SiteRoot {
	if ($Site) {
		return Resolve-LocalSiteRoot $Site
	}
	$root = Resolve-WpRoot
	if (-not $root) {
		throw "Not inside a WordPress root and no -Site given. Run from Local's site shell (app\public) or pass -Site <name>."
	}
	Write-Ok "Detected WordPress root: $root"
	return $root
}

function Assert-EmptyTarget([string]$Target) {
	if (-not (Test-Path -LiteralPath $Target)) { return }
	$existing = Get-ChildItem -LiteralPath $Target -Force -ErrorAction SilentlyContinue
	if (-not $existing) { return }
	if (-not $Force) {
		throw "Target directory already contains files: $Target (pass -Force to scaffold over it - existing files are overwritten, extra files are kept)."
	}
	Write-Warn "Target exists with files; -Force given, scaffolding over it."
}

function Invoke-ProjectInstall([string]$Dir) {
	Write-Step "Installing dependencies in $Dir"
	Push-Location $Dir
	try {
		if (Get-Command npm -ErrorAction SilentlyContinue) {
			Write-Host "    npm install --no-fund --no-audit" -ForegroundColor DarkGray
			npm install --no-fund --no-audit
			if ($LASTEXITCODE -ne 0) { throw "npm install failed (exit code $LASTEXITCODE)." }
		} else {
			Write-Warn "npm not found on PATH - install Node.js, then run 'cd $Dir && npm install'"
		}
	} finally { Pop-Location }

	if (-not (Get-Command composer -ErrorAction SilentlyContinue)) {
		Write-Warn "composer not found on PATH - run 'cd $Dir && composer install' manually"
		return
	}
	$phpExe = Get-Command php -ErrorAction SilentlyContinue
	$envBackup = $env:PHPRC
	$tempIni = $null
	try {
		if ($phpExe -and $phpExe.Source -match "lightning-services") {
			Write-Ok "Local's bundled PHP detected - enabling openssl/mbstring via temp php.ini"
			$phpDir = Split-Path $phpExe.Source -Parent
			$origIni = Join-Path $phpDir "php.ini"
			$workaround = "`r`n; setup.ps1 workaround: Local's bundled PHP ships with openssl/mbstring disabled`r`nextension=openssl`r`nextension=mbstring`r`n"
			$content = if (Test-Path -LiteralPath $origIni) { (Get-Content -LiteralPath $origIni -Raw) + $workaround } else { $workaround }
			$tempIni = Join-Path $env:TEMP ("local-php-" + [guid]::NewGuid().ToString("N") + ".ini")
			[System.IO.File]::WriteAllText($tempIni, $content, (New-Object System.Text.UTF8Encoding($false)))
			$env:PHPRC = $tempIni
		} else {
			Write-Ok "PHP on PATH is not Local's bundled build - plain composer install"
		}
		Push-Location $Dir
		try {
			Write-Host "    composer install" -ForegroundColor DarkGray
			composer install
			if ($LASTEXITCODE -ne 0) { throw "composer install failed (exit code $LASTEXITCODE)." }
		} finally { Pop-Location }
	} finally {
		if ($null -eq $envBackup) { Remove-Item Env:PHPRC -ErrorAction SilentlyContinue }
		else { $env:PHPRC = $envBackup }
		if ($tempIni) { Remove-Item -LiteralPath $tempIni -Force -ErrorAction SilentlyContinue }
	}
}

if ($Validate -or (-not $NewTheme -and -not $NewPlugin -and -not $Theme -and -not $Plugin)) {
	Invoke-Validate
	exit 0
}

$Kind = ""
$TargetPath = ""
if ($NewTheme) { $TargetPath = $NewTheme; $Kind = "theme" }
elseif ($NewPlugin) { $TargetPath = $NewPlugin; $Kind = "plugin" }
elseif ($Theme) {
	if (-not $Slug) { $Slug = $Theme }
	$TargetPath = Join-Path (Resolve-SiteRoot) "wp-content\themes\$Theme"
	$Kind = "theme"
}
elseif ($Plugin) {
	if (-not $Slug) { $Slug = $Plugin }
	$TargetPath = Join-Path (Resolve-SiteRoot) "wp-content\plugins\$Plugin"
	$Kind = "plugin"
}

Resolve-Args $TargetPath $Kind
Assert-EmptyTarget $TargetPath
New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
$ResolvedTarget = (Resolve-Path -LiteralPath $TargetPath).Path
Expand-Template "$RepoRoot\templates\$Kind" $ResolvedTarget $Tokens

if ($Install -and -not $DryRun) {
	Invoke-ProjectInstall $ResolvedTarget
}

if (-not $DryRun) {
	Write-Step "Next steps"
	Write-Host "  1. cd $ResolvedTarget"
	if (-not $Install) {
		Write-Host "  2. npm install"
		Write-Host "  3. composer install"
		Write-Host "  4. Edit style.css/readme.txt metadata and ACF field groups"
		Write-Host "  5. Activate in wp-admin, then run: npm run build / npm run format:all:check / vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M / vendor/bin/phpstan analyse --no-progress --memory-limit=1G"
	} else {
		Write-Host "  2. Activate in wp-admin (themes: Appearance > Themes; plugins: Plugins)"
		Write-Host "     ACF field groups load from acf-json/ on the ACF Sync page"
		Write-Host "  3. Run: npm run build / npm run format:all:check / vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M / vendor/bin/phpstan analyse --no-progress --memory-limit=1G"
	}
}
