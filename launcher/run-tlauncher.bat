@echo off
setlocal
REM Hardened TLauncher. Everything (settings, logins, game files, worlds, mods) stays in this folder's "data" subfolder.
REM Your normal %APPDATA%\.minecraft and the original TLauncher are never touched.
REM Usage: run-tlauncher.bat          = with a console window (shows errors)
REM        run-tlauncher.bat silent   = no console (used by "Start TLauncher.vbs")
cd /d "%~dp0"
set "MODE=%~1"
set "REALAPPDATA=%APPDATA%"
set "APPDATA=%~dp0data"
if not exist "%APPDATA%\.minecraft\mods" mkdir "%APPDATA%\.minecraft\mods"
set "VER=2.9381"
if exist "version.txt" set /p VER=<version.txt

REM One-time: offer to COPY (not move) worlds/settings from your normal .minecraft
if not exist "data\.copied-once" if exist "%REALAPPDATA%\.minecraft\saves" if /i not "%MODE%"=="silent" (
  echo Found your existing worlds in "%REALAPPDATA%\.minecraft"
  choice /m "Copy worlds, settings, resource packs and screenshots into this folder (originals are kept)"
  if not errorlevel 2 (
    for %%D in (saves resourcepacks shaderpacks screenshots) do if exist "%REALAPPDATA%\.minecraft\%%D" robocopy "%REALAPPDATA%\.minecraft\%%D" "%APPDATA%\.minecraft\%%D" /E /XC /XN /XO /NFL /NDL /NJH /NJS >nul
    for %%F in (options.txt servers.dat) do if exist "%REALAPPDATA%\.minecraft\%%F" if not exist "%APPDATA%\.minecraft\%%F" copy "%REALAPPDATA%\.minecraft\%%F" "%APPDATA%\.minecraft\" >nul
    echo   copied.
  )
  echo done> "data\.copied-once"
)
if not exist "data\.copied-once" echo done> "data\.copied-once"

REM Security: remove any saved "turn off HTTPS certificate checks" flag left by older versions
if exist "data\.tlauncher" for /r "data\.tlauncher" %%F in (*.properties) do (
  findstr /b /c:"ssl.deactivate.date" "%%F" >nul 2>&1 && (findstr /v /b /c:"ssl.deactivate.date" "%%F" > "%%F.tmp" & move /y "%%F.tmp" "%%F" >nul)
)

REM Pre-set mods: any .jar in "mods-preset" is copied into the game's mods folder (existing files are never overwritten)
if exist "mods-preset\*.jar" robocopy "mods-preset" "%APPDATA%\.minecraft\mods" *.jar /XC /XN /XO /NFL /NDL /NJH /NJS >nul

set JOPTS=-Dprism.order=d3d,sw  -Dsun.java2d.uiScale.enabled=false -Xms64m -Xmx768m -XX:+UseG1GC -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=30 -XX:G1PeriodicGCInterval=15000 -Dfile.encoding=UTF8 -Djava.net.preferIPv4Stack=true --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.desktop/java.awt=ALL-UNNAMED --add-opens=java.desktop/sun.awt.image=ALL-UNNAMED --add-opens=java.desktop/sun.java2d=ALL-UNNAMED --add-opens=java.desktop/java.awt.color=ALL-UNNAMED --add-opens=java.desktop/java.awt.image=ALL-UNNAMED --add-opens=java.desktop/com.apple.eawt=ALL-UNNAMED --add-opens=java.base/java.util.regex=ALL-UNNAMED --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.desktop/java.beans=ALL-UNNAMED --add-opens=javafx.web/com.sun.webkit.network=ALL-UNNAMED --add-opens=javafx.web/javafx.scene.web=ALL-UNNAMED --add-opens=javafx.web/com.sun.webkit=ALL-UNNAMED --add-opens=javafx.web/com.sun.webkit.event=ALL-UNNAMED --module-path "javafx" --add-modules ALL-MODULE-PATH -cp "TLauncher-hardened.jar;lib\*"
set MAIN=org.tlauncher.tlauncher.rmo.TLauncher -currentAppVersion=%VER% -requireUpdate=false

if /i "%MODE%"=="silent" (
  start "" "%~dp0java\jre\bin\javaw.exe" %JOPTS% %MAIN%
  exit /b
)
"%~dp0java\jre\bin\java.exe" %JOPTS% %MAIN%
pause
