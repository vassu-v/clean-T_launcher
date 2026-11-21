@echo off
setlocal
title Uninstall hardened TLauncher
REM Removes ONLY this folder and the shortcuts it made. Your normal .minecraft and the original TLauncher are not touched.
set "HERE=%~dp0"
set "HERE=%HERE:~0,-1%"
echo.
echo This will remove hardened TLauncher from:
echo    %HERE%
echo (game files, settings, logins, mods and worlds inside its "data" folder)
echo Your normal %APPDATA%\.minecraft and original TLauncher are NOT touched.
echo.
choice /m "Continue"
if errorlevel 2 exit /b

echo Closing TLauncher / Minecraft started from this folder...
powershell -NoProfile -Command "$h=$env:HERE; Get-CimInstance Win32_Process -Filter \"Name like 'java%%'\" | Where-Object { ($_.ExecutablePath + ' ' + $_.CommandLine).IndexOf($h + '\',[StringComparison]::OrdinalIgnoreCase) -ge 0 } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"

set "DESK=%USERPROFILE%\Desktop"
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do if exist "%%D" set "DESK=%%D"
if exist "%HERE%\data\.minecraft\saves" (
  choice /m "Back up your worlds to the Desktop first"
  if not errorlevel 2 (
    robocopy "%HERE%\data\.minecraft\saves" "%DESK%\TLauncher-hardened-worlds-backup" /E /NFL /NDL /NJH /NJS >nul
    echo   Worlds saved to Desktop\TLauncher-hardened-worlds-backup
  )
)

for %%P in ("%USERPROFILE%\Desktop" "%APPDATA%\Microsoft\Windows\Start Menu\Programs") do (
  if exist "%%~P\TLauncher (hardened).lnk" del /q "%%~P\TLauncher (hardened).lnk"
)
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do if exist "%%D\TLauncher (hardened).lnk" del /q "%%D\TLauncher (hardened).lnk"

echo.
echo If you added lines from hosts-block.txt to your hosts file, you may keep them (they only block ad/telemetry hosts).
echo Deleting the folder in a moment...
cd /d "%TEMP%"
start "" /min cmd /c "timeout /t 3 /nobreak >nul & rmdir /s /q "%HERE%""
exit
