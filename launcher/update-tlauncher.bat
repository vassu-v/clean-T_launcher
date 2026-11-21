@echo off
REM Updates hardened TLauncher inside this folder only. Close TLauncher first.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-tlauncher.ps1" %*
pause
