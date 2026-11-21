@echo off
REM Installs/updates the mods in mods-list.txt (from Modrinth, fingerprint-checked) into this folder only.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-mods.ps1" %*
pause
