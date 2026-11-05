<#
.SYNOPSIS
	Snoozle OpenCode WordPress settings - validation and project scaffolding.

.DESCRIPTION
	This repo IS the global OpenCode config (~/.config/opencode), so there is
	nothing to install. This script runs under PowerShell 5.1+ (Windows) and
	pwsh 7+ (macOS/Linux). It:

	  * Default (-Validate):     checks skill/agent/command frontmatter and structure.
  * -NewTheme/-NewPlugin:    scaffolds into an explicit target directory.
  * -Theme/-Plugin:          scaffolds into wp-content/themes|plugins/{slug} of the
                             current WordPress root (any stack: XAMPP, MAMP, Local,
                             Linux checkout, Docker volume) or of -Site / -WpRoot.

Platform notes:
  * Windows: run via scaffold.cmd (works from cmd, Git Bash, PowerShell), or
    .\setup.ps1 directly from PowerShell.
  * macOS/Linux: run ./scaffold.sh or pwsh -File setup.ps1 (PowerShell 7+ required).
    When the PHP on PATH is a bundled build with openssl/mbstring disabled
    (e.g. Local's lightning-services PHP on Windows/macOS), -Install enables
    them via a temp php.ini; system PHP installs are used untouched.
  * Any WordPress checkout works: the root is detected by walking up for
    wp-load.php, or pass -Site <name> (a directory under -SitesDir) or
    -WpRoot <path> (an explicit root, e.g. a remote mount).

.PARAMETER Validate
	Run structural validation only (default).

.PARAMETER NewTheme
	Target directory for a new theme project (explicit path).

.PARAMETER NewPlugin
	Target directory for a new plugin project (explicit path).

.PARAMETER Theme
	Slug for a theme scaffolded into wp-content/themes/{slug}. The WordPress root is
	resolved by walking up from the current directory (any checkout with wp-load.php
	at its root), or from -Site / -WpRoot.

.PARAMETER Plugin
	Slug for a plugin scaffolded into wp-content/plugins/{slug}. Same root resolution.

.PARAMETER Site
	Site name; root resolves to {SitesDir}\{site} when that directory contains
	wp-load.php, else {SitesDir}\{site}\app\public (Local layout). Not needed when the
	current directory is already inside a WordPress root or -WpRoot is given.

.PARAMETER SitesDir
	Parent directory holding named sites (default: $HOME\Local Sites, the Local
	default — point it at htdocs, /var/www, or any folder on other stacks).
	Only used with -Site.

.PARAMETER WpRoot
	Explicit WordPress root path (any stack, including remote mounts and
	non-standard layouts). Takes precedence over the walk-up detection and -Site.

.PARAMETER Install
	After scaffolding, run npm install and composer install in the new project. When
	the PHP on PATH is a bundled build with openssl/mbstring disabled (e.g. Local's
	lightning-services PHP), a temp php.ini with both enabled is used via PHPRC;
	system PHP installs are used untouched.

.PARAMETER Force
	Allow scaffolding into an existing non-empty target directory (files are merged;
	existing files are overwritten, extra files are kept).

.PARAMETER Slug
	Project slug (folder name + text domain, dashes allowed). Default: target folder
	name (for -Theme/-Plugin: the slug itself).

.PARAMETER Prefix
	Function/class prefix (e.g. "snoozle_"). WPCS requires at least 4 characters
	after stripping the trailing underscore. Default: first 4 letters of slug + "_".

.PARAMETER Name
	Human-readable project name. Default: slug title-cased.

.PARAMETER DryRun
	Report what would be done without writing.

.EXAMPLE
	.\setup.ps1 -Validate
	.\setup.ps1 -NewTheme ..\wp-content\themes\snoozle -Slug snoozle -Prefix snoozle_ -Name "Snoozle Studio"
	.\setup.ps1 -NewPlugin .\my-plugin -Slug my-plugin -Prefix myplugin_ -Name "My Plugin"
	# From a site shell on Windows (cmd.exe by default - use scaffold.cmd):
	scaffold.cmd -Theme mytheme -Prefix mytheme_ -Name "My Theme"
	scaffold.cmd -Plugin my-plugin -Install
	# From inside any WordPress checkout (XAMPP htdocs, MAMP, Local site shell, Linux):
	.\setup.ps1 -Theme mytheme -Prefix mytheme_ -Name "My Theme"
	# macOS/Linux (POSIX shell; repo at ~/.config/opencode):
	./scaffold.sh -Theme mytheme -Prefix mytheme_ -Name "My Theme" -Install
	# From anywhere, targeting a site by name (plain dir or Local app/public layout):
	.\setup.ps1 -Site mysite -Theme mytheme -Install
	# From anywhere, targeting an explicit root (any stack, remote mounts):
	.\setup.ps1 -WpRoot D:\xampp\htdocs\mysite -Theme mytheme -DryRun
	.\setup.ps1 -Theme demo -SitesDir D:\xampp\htdocs -DryRun
#>
#requires -Version 5.1
param(
	[switch]$Validate,
	[string]$NewTheme,
	[string]$NewPlugin,
	[string]$Theme,
	[string]$Plugin,
	[string]$Site,
	[string]$SitesDir,
	[string]$WpRoot,
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
	$content = Get-Content -LiteralPath $File -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
	if (-not $content) { Write-Fail "${Kind} $File is empty or unreadable"; return $false }
	if ($content -notmatch '^---\r?\n') { Write-Fail "${Kind} $File has no frontmatter"; return $false }
	if ($content -notmatch '(?m)^description:\s*.+') { Write-Fail "${Kind} $File has no description"; return $false }
	# Plain YAML scalars cannot contain ': ' (colon+space) - it starts a mapping
	# and the frontmatter fails to parse, silently killing the component's
	# routing. Quoted values (starting with ' or ") are exempt.
	if ($content -match '(?m)^description:\s*[^\s''"][^\r\n]*: ') {
		Write-Fail "${Kind} $File - description contains ': ' (colon+space) - invalid in a plain YAML scalar, breaks frontmatter parsing"
		return $false
	}
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

function Assert-RenderedFile([string]$Relative, [string]$Dest, [string]$Content) {
	# Validate BEFORE anything is written: no stray placeholders, no reserved
	# Windows names, JSON/XML files parse. Both -DryRun and the real write path
	# run this, so a broken scaffold can never be written silently.
	$stray = [regex]::Match($Content, '\{[a-zA-Z_][a-zA-Z0-9_-]*\}')
	if ($stray.Success) {
		throw "Scaffold validation failed: stray placeholder '$($stray.Value)' in $Relative"
	}
	$leaf = Split-Path $Dest -Leaf
	if ($leaf -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)') {
		throw "Scaffold validation failed: '$leaf' is a reserved Windows file name"
	}
	if ($Relative.EndsWith(".json")) {
		try {
			[void](ConvertFrom-Json -InputObject $Content -ErrorAction Stop)
		} catch {
			throw "Scaffold validation failed: $Relative is not valid JSON"
		}
	} elseif ($Relative.EndsWith(".xml")) {
		try {
			[void]([xml]$Content)
		} catch {
			throw "Scaffold validation failed: $Relative is not valid XML"
		}
	}
}

function Expand-Template([string]$Source, [string]$Destination, [hashtable]$Tokens) {
	Write-Step "Scaffolding from $Source"
	$items = Get-ChildItem -LiteralPath $Source -Recurse -Force
	foreach ($item in $items) {
		$relative = $item.FullName.Substring($Source.Length).TrimStart("\", "/")
		foreach ($key in $Tokens.Keys) {
			$relative = $relative.Replace($key, $Tokens[$key])
		}
		$dest = Join-Path $Destination $relative
		if ($item.PSIsContainer) {
			if (-not $DryRun) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
			continue
		}
		if ($DryRun) {
			$content = Get-Content -LiteralPath $item.FullName -Raw -Encoding UTF8
			foreach ($key in $Tokens.Keys) {
				$content = $content.Replace($key, $Tokens[$key])
			}
			Assert-RenderedFile $relative $dest $content
			Write-Ok "would write $relative"
			continue
		}
		if (Test-Path -LiteralPath $dest) {
			$existing = Get-Item -LiteralPath $dest -Force
			if ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
				throw "Refusing to write through a symlink/reparse point: $relative"
			}
		}
		New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
		$content = Get-Content -LiteralPath $item.FullName -Raw -Encoding UTF8
		foreach ($key in $Tokens.Keys) {
			$content = $content.Replace($key, $Tokens[$key])
		}
		Assert-RenderedFile $relative $dest $content
		$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
		[System.IO.File]::WriteAllText($dest, $content, $utf8NoBom)
		Write-Ok "wrote $relative"
	}
}

function Assert-SafePathValues {
	# -Site/-Theme/-Plugin are slugs/names, never paths: reject traversal up
	# front, BEFORE any site-root resolution or path construction. -Target stays
	# unvalidated (it is a real path, e.g. "..\wp-content\themes\mytheme").
	foreach ($v in @($Site, $Theme, $Plugin)) {
		if ($v -and $v -match '[\\/:"]|\.\.') {
			throw "Invalid value for -Site/-Theme/-Plugin: '$v' (no path separators, quotes or '..' allowed)."
		}
	}
}

function Resolve-Args([string]$Target, [string]$Kind) {
	if (-not $Target) { throw "Missing target directory (use -NewTheme, -NewPlugin, -Theme or -Plugin)." }
	$script:Target = $Target
	if (-not $Slug) { $script:Slug = Split-Path $Target -Leaf }
	if (-not $Prefix) {
		$letters = ($Slug -replace '-', '')
		if ($letters.Length -lt 4) {
			throw "Cannot derive a 4-character prefix from slug '$Slug' - pass -Prefix with at least 4 characters (e.g. 'myco_')."
		}
		$script:Prefix = $letters.Substring(0, 4) + "_"
	}
	if (-not $Name) { $script:Name = (Get-Culture).TextInfo.ToTitleCase(($Slug -replace '-', ' ')) }

	# Validate before values reach paths or generated identifiers. The
	# Site/Theme/Plugin traversal check already ran in Assert-SafePathValues
	# (before site-root resolution); here we validate the generated identifiers.
	if ($script:Slug -notmatch '^[a-z0-9][a-z0-9-]*$') {
		throw "Invalid slug '$script:Slug' - use lowercase letters, digits and hyphens only."
	}
	if ($script:Prefix -notmatch '^[a-z][a-z0-9_]*$') {
		throw "Invalid prefix '$script:Prefix' - use lowercase letters, digits and underscores only, starting with a letter."
	}
	if ($script:Name -notmatch '^[\w .\-]+$') {
		throw "Invalid name '$script:Name' - use letters, digits, spaces, dots and hyphens only."
	}

	# The prefix token carries no trailing underscore: templates use
	# {prefix}_function_name, so prefix "myco_" yields "myco_function_name".
	# WPCS 3.2+ requires prefixes of at least 4 characters and reserves
	# wp/wordpress/php - reject those here so a scaffold never starts red.
	$base = $Prefix.TrimEnd("_")
	if ($base.Length -lt 4) {
		throw "Prefix '$Prefix' is too short: WPCS requires at least 4 characters after the trailing underscore (e.g. 'myco_')."
	}
	if (@('wp', 'wordpress', 'php') -contains $base.ToLowerInvariant()) {
		throw "Prefix '$Prefix' is reserved by WordPress/WPCS - choose a project-specific prefix."
	}
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

function Resolve-NamedSiteRoot([string]$SiteName) {
	$sitesRoot = if ($SitesDir) { $SitesDir } else { Join-Path $HOME "Local Sites" }
	if (-not (Test-Path -LiteralPath $sitesRoot)) {
		throw "Sites directory not found: $sitesRoot (pass -SitesDir to override)."
	}
	$siteDir = Join-Path $sitesRoot $SiteName
	if (-not (Test-Path -LiteralPath $siteDir)) {
		$available = ((Get-ChildItem -LiteralPath $sitesRoot -Directory -ErrorAction SilentlyContinue).Name) -join ", "
		throw "Site '$SiteName' not found in $sitesRoot. Available sites: $available"
	}
	# Stack-neutral layout: the site directory itself is the WordPress root on
	# XAMPP/MAMP/plain checkouts; Local nests it under app/public.
	if (Test-Path (Join-Path $siteDir "wp-load.php")) {
		Write-Ok "Site '$SiteName' root: $siteDir"
		return $siteDir
	}
	$public = Join-Path $siteDir (Join-Path "app" "public")
	if (-not (Test-Path (Join-Path $public "wp-load.php"))) {
		throw "Site '$SiteName' root not found (expected wp-load.php in $siteDir or $public)."
	}
	Write-Ok "Site '$SiteName' root: $public"
	return $public
}

function Resolve-SiteRoot {
	if ($WpRoot) {
		if (-not (Test-Path (Join-Path $WpRoot "wp-load.php"))) {
			throw "-WpRoot '$WpRoot' is not a WordPress root (wp-load.php not found)."
		}
		return $WpRoot
	}
	if ($Site) {
		return Resolve-NamedSiteRoot $Site
	}
	$root = Resolve-WpRoot
	if (-not $root) {
		throw "Not inside a WordPress root and no -Site or -WpRoot given. Run from inside a WordPress checkout (any stack) or pass -Site <name> / -WpRoot <path>."
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
	if (-not (Test-Path (Join-Path $Dir ".git"))) {
		Write-Warn "No .git in $Dir - Husky will not install the pre-commit hook. Run 'git init' and 'npm install' again to enable it."
	}
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
			Write-Ok "Bundled PHP with openssl/mbstring disabled detected - enabling via temp php.ini"
			$phpDir = Split-Path $phpExe.Source -Parent
			$origIni = Join-Path $phpDir "php.ini"
			$workaround = "`r`n; setup.ps1 workaround: Local's bundled PHP ships with openssl/mbstring disabled`r`nextension=openssl`r`nextension=mbstring`r`n"
			$content = if (Test-Path -LiteralPath $origIni) { (Get-Content -LiteralPath $origIni -Raw -Encoding UTF8) + $workaround } else { $workaround }
			$tempIni = Join-Path $env:TEMP ("local-php-" + [guid]::NewGuid().ToString("N") + ".ini")
			[System.IO.File]::WriteAllText($tempIni, $content, (New-Object System.Text.UTF8Encoding($false)))
			$env:PHPRC = $tempIni
		} else {
			Write-Ok "System PHP on PATH - plain composer install"
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

Assert-SafePathValues

$Kind = ""
$TargetPath = ""
if ($NewTheme) { $TargetPath = $NewTheme; $Kind = "theme" }
elseif ($NewPlugin) { $TargetPath = $NewPlugin; $Kind = "plugin" }
elseif ($Theme) {
	if (-not $Slug) { $Slug = $Theme }
	$TargetPath = Join-Path (Resolve-SiteRoot) (Join-Path "wp-content" (Join-Path "themes" $Theme))
	$Kind = "theme"
}
elseif ($Plugin) {
	if (-not $Slug) { $Slug = $Plugin }
	$TargetPath = Join-Path (Resolve-SiteRoot) (Join-Path "wp-content" (Join-Path "plugins" $Plugin))
	$Kind = "plugin"
}

Resolve-Args $TargetPath $Kind
Assert-EmptyTarget $TargetPath
if (-not $DryRun) {
	New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
	$ResolvedTarget = (Resolve-Path -LiteralPath $TargetPath).Path
} else {
	$ResolvedTarget = [System.IO.Path]::GetFullPath($TargetPath)
}
Expand-Template "$RepoRoot\templates\$Kind" $ResolvedTarget $Tokens

if ($Install -and -not $DryRun) {
	Invoke-ProjectInstall $ResolvedTarget
}

if (-not $DryRun) {
	Write-Step "Next steps"
	Write-Host "  1. cd $ResolvedTarget"
	$step = 2
	if (-not $Install) {
		Write-Host "  $step. npm install"; $step++
		Write-Host "  $step. composer install"; $step++
	}
	if (-not (Test-Path (Join-Path $ResolvedTarget ".git"))) {
		Write-Host "  $step. git init (required to install the Husky pre-commit hook)"; $step++
		Write-Host "     then re-run npm install to install the hook"
	}
	if ($Kind -eq "theme") {
		Write-Host "  $step. Edit style.css metadata and ACF field groups"; $step++
	} else {
		Write-Host "  $step. Edit the plugin header and readme.txt metadata"; $step++
	}
	Write-Host "  $step. Activate in wp-admin, then run the verification chain:"
	Write-Host "     npm run build / npm run format:all:check / vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M / vendor/bin/phpstan analyse --no-progress --memory-limit=1G"
	Write-Host "     On Windows PowerShell/cmd use: php vendor/bin/phpcs ... / php vendor/bin/phpstan ..."
}
