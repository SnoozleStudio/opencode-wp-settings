@echo off
rem Scaffold a WordPress theme or plugin into the current WordPress root (Local site shell).
rem
rem Usage (from Local's site shell, cwd = <site>\app\public):
rem   scaffold.cmd -Theme mytheme -Prefix mt_ -Name "My Theme"
rem   scaffold.cmd -Plugin my-plugin -Install
rem   scaffold.cmd -Site mysite -Theme mytheme -Install
rem
rem Forwards all arguments to setup.ps1. Works from cmd.exe (Local's Windows site
rem shell default), Git Bash, and PowerShell. Uses this script's own directory so
rem any checkout location works.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
exit /b %ERRORLEVEL%
