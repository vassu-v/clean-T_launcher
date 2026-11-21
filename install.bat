@echo off
setlocal
title Hardened TLauncher installer
REM One file is enough: put this anywhere (e.g. C:\Games) and double-click it.
REM It creates a portable "TLauncher-hardened" folder next to itself. Nothing is installed system-wide.
cd /d "%~dp0"
set "TLDIR=%~dp0"
if not exist "%~dp0install.ps1" (
  echo Downloading installer from GitHub...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/vassu-v/clean-t_launcher/main/install.ps1' -OutFile (Join-Path $env:TLDIR 'install.ps1')"
)
if not exist "%~dp0install.ps1" (
  echo Could not download the installer. Check your internet connection.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
pause
