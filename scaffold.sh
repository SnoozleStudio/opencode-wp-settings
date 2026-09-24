#!/bin/sh
# Scaffold a WordPress theme or plugin (macOS/Linux counterpart of scaffold.cmd).
#
# Usage (repo at ~/.config/opencode):
#   ./scaffold.sh -NewTheme ./mytheme -Slug mytheme -Prefix mt_ -Name "My Theme"
#   ./scaffold.sh -Theme mytheme -Prefix mt_ -Name "My Theme" -Install
#   ./scaffold.sh -Site mysite -Theme mytheme -Install
#
# Forwards all arguments to setup.ps1 via pwsh (PowerShell 7+, required).
# The script location is resolved with dirname, so it works from any checkout.
exec pwsh -NoProfile -File "$(dirname "$0")/setup.ps1" "$@"