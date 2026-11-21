# Hardened TLauncher - one-click installer for Windows 10/11 (64-bit).
# Creates a portable "TLauncher-hardened" folder. Nothing is installed system-wide.
#  1. downloads the launcher scripts from GitHub (vassu-v/clean-t_launcher)
#  2. downloads Eclipse Temurin JDK 21 (SHA-256 checked) and builds a small private Java with jlink
#  3. downloads TLauncher + its libraries from TLauncher's own server (SHA-1 checked) and applies the security patches
param([string]$Dest = '', [switch]$Quiet, [string]$Source = '')
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$RepoZip = 'https://codeload.github.com/vassu-v/clean-t_launcher/zip/refs/heads/main'
$JdkUrl  = 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.13%2B9/OpenJDK21U-jdk_x64_windows_hotspot_21.0.13_9.zip'
$JdkSha  = 'a4dbaa05fca4bd89d84584e58c459bd732efebb1722af80ab13c6516832004f9'
$Modules = 'java.base,java.compiler,java.datatransfer,java.xml,java.prefs,java.desktop,java.instrument,java.logging,java.management,java.security.sasl,java.naming,java.rmi,java.management.rmi,java.net.http,java.scripting,java.security.jgss,java.transaction.xa,java.sql,java.sql.rowset,java.xml.crypto,java.se,java.smartcardio,jdk.accessibility,jdk.internal.jvmstat,jdk.attach,jdk.charsets,jdk.internal.opt,jdk.zipfs,jdk.compiler,jdk.crypto.ec,jdk.crypto.cryptoki,jdk.crypto.mscapi,jdk.dynalink,jdk.internal.ed,jdk.editpad,jdk.hotspot.agent,jdk.httpserver,jdk.incubator.vector,jdk.internal.le,jdk.internal.vm.ci,jdk.internal.vm.compiler,jdk.internal.vm.compiler.management,jdk.jartool,jdk.javadoc,jdk.jcmd,jdk.management,jdk.management.agent,jdk.jconsole,jdk.jdeps,jdk.jdwp.agent,jdk.jdi,jdk.jfr,jdk.jlink,jdk.jpackage,jdk.jshell,jdk.jsobject,jdk.jstatd,jdk.localedata,jdk.management.jfr,jdk.naming.dns,jdk.naming.rmi,jdk.net,jdk.nio.mapmode,jdk.random,jdk.sctp,jdk.security.auth,jdk.security.jgss,jdk.unsupported,jdk.unsupported.desktop,jdk.xml.dom'

function Say($m, $c = 'Gray') { Write-Host $m -ForegroundColor $c }
function Fail($m) { Say ''; Say "ERROR: $m" Red; Say 'Nothing outside the install folder was changed. You can run install.bat again.' Yellow; exit 1 }

Say '=== Hardened TLauncher installer ===' Cyan
# ---- edge-case checks ----
if ($PSVersionTable.PSVersion.Major -lt 5) { Fail 'PowerShell 5 or newer is needed (Windows 10/11 have it built in).' }
if (-not [Environment]::Is64BitOperatingSystem) { Fail 'A 64-bit Windows is required (32-bit is not supported by Java 21 / new Minecraft).' }
if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { Say 'Note: ARM64 Windows detected - the x64 build will run through Windows emulation (slower).' Yellow }

if (-not $Dest) { $Dest = Join-Path $PSScriptRoot 'TLauncher-hardened' }
$Dest = [IO.Path]::GetFullPath($Dest)
if ($Dest.Length -gt 180) { Fail "The install path is too long ($($Dest.Length) characters). Put install.bat in a shorter folder, e.g. C:\Games." }
if ($Dest -like "$env:windir*" -or $Dest -like "$env:ProgramFiles*" -or $Dest -like "${env:ProgramFiles(x86)}*") { Fail 'Please do not install into Windows or Program Files (needs admin rights). Use e.g. C:\Games or your Desktop.' }
Say "Install folder: $Dest"

$drive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($Dest))
if ($drive.AvailableFreeSpace -lt 2GB) { Fail ("Not enough free disk space on {0} (need about 2 GB for setup, plus room for game files)." -f $drive.Name) }

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
try { [IO.File]::WriteAllText((Join-Path $Dest '.write-test'), 'ok'); Remove-Item (Join-Path $Dest '.write-test') } catch { Fail "Cannot write to $Dest (permissions or antivirus 'Controlled folder access')." }

$tmp = Join-Path $Dest '_setup'
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

function Get-File($url, $out) {
  for ($i = 1; $i -le 3; $i++) {
    try { Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -UserAgent 'hardened-tlauncher-installer'; return }
    catch { Say "  download attempt $i failed: $($_.Exception.Message)" Yellow; Start-Sleep -Seconds (3 * $i) }
  }
  Fail "Could not download $url. Check your internet connection / firewall and try again."
}

try {
  # ---- 1. scripts ----
  Say '[1/3] Downloading launcher scripts from GitHub...' Cyan
  if ($Source) {
    $src = Get-Item $Source   # local copy of this project (used by the automated Windows test)
  } else {
    $rz = Join-Path $tmp 'repo.zip'
    Get-File $RepoZip $rz
    [IO.Compression.ZipFile]::ExtractToDirectory($rz, (Join-Path $tmp 'repo'))
    $src = Get-ChildItem (Join-Path $tmp 'repo') -Directory | Select-Object -First 1
  }
  $launcherSrc = Join-Path $src.FullName 'launcher'
  if (-not (Test-Path (Join-Path $launcherSrc 'run-tlauncher.bat'))) { Fail 'The downloaded project looks incomplete.' }
  # keep the user's own mod list if they already have one
  $ml = Join-Path $Dest 'mods-list.txt'; $mlKeep = $null
  if (Test-Path $ml) { $mlKeep = Get-Content $ml -Raw }
  Copy-Item (Join-Path $launcherSrc '*') $Dest -Recurse -Force
  if ($mlKeep) { [IO.File]::WriteAllText($ml, $mlKeep) }
  Copy-Item (Join-Path $src.FullName 'install.ps1') $Dest -Force
  Copy-Item (Join-Path $src.FullName 'install.bat') $Dest -Force

  # ---- 2. private Java ----
  $jre = Join-Path $Dest 'java\jre'
  if (Test-Path (Join-Path $jre 'bin\javaw.exe')) {
    Say '[2/3] Private Java already present - skipped.' Cyan
  } else {
    Say '[2/3] Downloading Java 21 (Eclipse Temurin, about 200 MB)...' Cyan
    $jz = Join-Path $tmp 'jdk.zip'
    Get-File $JdkUrl $jz
    if ((Get-FileHash $jz -Algorithm SHA256).Hash -ine $JdkSha) { Fail 'Java download fingerprint mismatch - stopped for safety.' }
    Say '      Building a small private Java for TLauncher...'
    [IO.Compression.ZipFile]::ExtractToDirectory($jz, (Join-Path $tmp 'jdk'))
    $jdk = Get-ChildItem (Join-Path $tmp 'jdk') -Directory | Select-Object -First 1
    if (Test-Path $jre) { Remove-Item $jre -Recurse -Force }
    New-Item -ItemType Directory -Force -Path (Split-Path $jre) | Out-Null
    & (Join-Path $jdk.FullName 'bin\jlink.exe') --add-modules $Modules --output $jre --strip-debug --no-man-pages --no-header-files --compress=zip-6
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $jre 'bin\javaw.exe'))) { Fail 'Building the private Java failed.' }
  }

  # ---- 3. launcher + libraries + patches ----
  Say '[3/3] Downloading TLauncher and applying security patches...' Cyan
  & (Join-Path $Dest 'update-tlauncher.ps1') -Force
  if (-not (Test-Path (Join-Path $Dest 'TLauncher-hardened.jar'))) { Fail 'Launcher download/patch did not finish.' }
} catch {
  Fail $_.Exception.Message
} finally {
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}

Say ''
Say 'Installed!' Green
Say "Folder: $Dest"
Say 'Start it with "Start TLauncher.vbs" (or run-tlauncher.bat to see errors).'
if ($Quiet) { exit 0 }
$a = Read-Host 'Create a Desktop / Start menu shortcut now? (Y/N)'
if ($a -match '^[Yy]') { Start-Process wscript.exe -ArgumentList ('"' + (Join-Path $Dest 'Create Desktop Shortcut.vbs') + '"') }
$b = Read-Host 'Start TLauncher now? (Y/N)'
if ($b -match '^[Yy]') { Start-Process wscript.exe -ArgumentList ('"' + (Join-Path $Dest 'Start TLauncher.vbs') + '"') }
