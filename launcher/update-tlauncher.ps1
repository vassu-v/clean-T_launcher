# Updates hardened TLauncher IN THIS FOLDER ONLY. Nothing outside this folder is written.
#  1. asks TLauncher's server (HTTPS only) for the latest version info
#  2. downloads the new launcher + libraries into "update-staging" and checks every SHA1 fingerprint
#  3. re-applies the security patches (no telemetry, no ad check, no unsafe updater, HTTPS mirrors only)
#  4. moves the old version to "backup\<old version>" and puts the new one in place
# If anything fails, your current version is left exactly as it was.
param([switch]$Force)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$root = $PSScriptRoot
$stage = Join-Path $root 'update-staging'
$repos = @('https://repo.tlauncher.org/tlauncher-sources/prod/release/tlauncher/',
           'https://repo.tlauncher.ru/tlauncher-sources/prod/release/tlauncher/')
$ua = 'Java/21'

function Get-Text($rel) {
  foreach ($r in $repos) {
    try { $c = (Invoke-WebRequest -Uri ($r + $rel) -UserAgent $ua -UseBasicParsing).Content; if ($c -is [byte[]]) { $c = [Text.Encoding]::UTF8.GetString($c) }; return $c } catch { Write-Host "  mirror failed: $r" }
  }
  throw "Could not reach TLauncher's server for $rel"
}
function Get-Sha1($p) { (Get-FileHash $p -Algorithm SHA1).Hash.ToLower() }
function Get-Verified($rel, $dest, $sha1) {
  if ((Test-Path $dest) -and ((Get-Sha1 $dest) -eq $sha1.ToLower())) { return }
  New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
  foreach ($r in $repos) {
    try {
      Invoke-WebRequest -Uri ($r + $rel) -OutFile $dest -UserAgent $ua -UseBasicParsing
      if ((Get-Sha1 $dest) -eq $sha1.ToLower()) { return }
      Write-Host "  fingerprint mismatch from $r"
    } catch { Write-Host "  mirror failed: $r" }
    Remove-Item $dest -ErrorAction SilentlyContinue
  }
  throw "FINGERPRINT CHECK FAILED for $rel - update stopped for safety, nothing changed."
}
function Get-Bytes($s) { $ms = New-Object IO.MemoryStream; $s.CopyTo($ms); $s.Close(); $ms.ToArray() }

$cur = '0'
if (Test-Path (Join-Path $root 'version.txt')) { $cur = (Get-Content (Join-Path $root 'version.txt') -TotalCount 1).Trim() }
Write-Host "Installed version: $cur"
Write-Host 'Checking for updates (HTTPS)...'
$app = Get-Text 'appConfig.json' | ConvertFrom-Json
$new = [string]$app.appVersion
Write-Host "Latest version:    $new"
if ($new -eq $cur -and -not $Force) { Write-Host 'You already have the latest version. Nothing to do.'; return }

# Safety: this folder ships its own Java 21. If TLauncher ever moves to a newer Java, stop instead of breaking.
$javaCfg = [string]$app.javaRepo.resources[0].path
if ($javaCfg -and $javaCfg -ne 'javaConfig21.json') {
  Write-Host "This TLauncher version needs a different Java ($javaCfg). Update stopped - nothing changed." -ForegroundColor Yellow
  Write-Host 'Ask for a new full package, or keep using the current version (it keeps working).'
  return
}
if ([string]$app.mainClass -ne 'org.tlauncher.tlauncher.rmo.TLauncher') {
  Write-Host "This TLauncher version starts differently ($($app.mainClass)). Update stopped - nothing changed." -ForegroundColor Yellow
  return
}
$running = Get-CimInstance Win32_Process -Filter "Name like 'java%'" | Where-Object { ($_.ExecutablePath + ' ' + $_.CommandLine).IndexOf($root + '\', [StringComparison]::OrdinalIgnoreCase) -ge 0 }
if ($running) { Write-Host 'Close TLauncher and Minecraft first, then run the update again. Nothing changed.' -ForegroundColor Yellow; return }

if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

# dependency list, pinned by appConfig's SHA1
$depRes = $app.appDependencies.resources[0]
Get-Verified $depRes.relativeUrl (Join-Path $stage 'dependencies.json') $depRes.sha1
$deps = Get-Content (Join-Path $stage 'dependencies.json') -Raw | ConvertFrom-Json

Write-Host "Downloading $($deps.resources.Count) libraries (already-matching files are reused)..."
foreach ($d in $deps.resources) {
  $name = Split-Path $d.path -Leaf
  if ($name -match '^javafx-.*\.jar$') {
    if ($name -notmatch '-win\.jar$') { continue }      # non-Windows stubs break JavaFX
    $dest = Join-Path $stage "javafx\$name"; $old = Join-Path $root "javafx\$name"
  } else {
    $dest = Join-Path $stage "lib\$name"; $old = Join-Path $root "lib\$name"
  }
  New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
  if ((Test-Path $old) -and ((Get-Sha1 $old) -eq $d.sha1.ToLower())) { Copy-Item $old $dest; continue }
  Write-Host "  $name"
  Get-Verified $d.relativeUrl $dest $d.sha1
}

$jarRes = $app.appFileRepo.resources[0]
Write-Host "Downloading launcher $($jarRes.path)..."
$orig = Join-Path $stage 'original.jar'
Get-Verified $jarRes.relativeUrl $orig $jarRes.sha1

Write-Host 'Applying security patches...'
$jar = Join-Path $stage 'TLauncher-hardened.jar'
Copy-Item $orig $jar
$z = [IO.Compression.ZipFile]::Open($jar, 'Update')
try {
  $e = $z.GetEntry('inner.tlauncher.properties')
  if (-not $e) { throw 'Patch target inner.tlauncher.properties not found - launcher changed; update stopped.' }
  $text = [Text.Encoding]::UTF8.GetString((Get-Bytes $e.Open()))
  $out = foreach ($line in ($text -split "`n")) {
    $ln = $line.TrimEnd("`r")
    if ($ln -notmatch '^#' -and $ln -match '^([^=]+)=(.*)$') {
      $k = $Matches[1]; $v = $Matches[2]
      if ($k -eq 'statistics.url' -or $k -eq 'skin.server.advertising' -or $k -eq 'log.system') { $v = 'https://localhost.invalid/' }
      elseif ($k -eq 'file.server.downloader.comparing') { $v = 'https://res.tlauncher.org/unb,https://res.tl.vg/unb' }
      elseif ($v -match 'https?://' -and $v.Contains(',')) {
        $keep = @($v.Split(',') | Where-Object { -not $_.StartsWith('http://') -and -not $_.Contains('fastrepo.org') })
        if ($keep.Count) { $v = ($keep -join ',') }
      }
      "$k=$v"
    } else { $ln }
  }
  # clean home screen: the start page comes from this project's GitHub page instead of TLauncher's ad/news page
  $out = @($out | Where-Object { -not "$_".StartsWith('home.page.repo=') })
  $txt = ($out -join "`n").TrimEnd("`n") + "`nhome.page.repo=https://raw.githubusercontent.com/vassu-v/clean-t_launcher/main/`n"
  $e.Delete()
  $w = New-Object IO.StreamWriter($z.CreateEntry('inner.tlauncher.properties').Open(), (New-Object Text.UTF8Encoding($false)))
  $w.Write($txt); $w.Close()

  # unsafe plain-HTTP "fix network" updater -> disabled (same-length swap keeps the class file valid)
  $latin = [Text.Encoding]::GetEncoding(28591)
  $bad = 'http://repo.tl.vg/update/downloads/libraries/org/tlauncher/updater/TLauncherUpdater.exe'
  $off = 'https://127.0.0.1/disabled/' + ('x' * ($bad.Length - 31)) + '.exe'
  # never switch off HTTPS certificate checks: calls to deactivateSSL() are redirected to the harmless createTimeStart()
  $sslOld = [string][char]1 + [char]0 + [char]13 + 'deactivateSSL'
  $sslNew = [string][char]1 + [char]0 + [char]15 + 'createTimeStart'
  $hpOld = [string][char]1 + [char]0 + [char]16 + 'main.server.repo'
  $hpNew = [string][char]1 + [char]0 + [char]14 + 'home.page.repo'
  $hit = 0; $ssl = 0; $hpHits = 0
  foreach ($e in @($z.Entries | Where-Object { $_.FullName -like '*.class' })) {
    $s = $latin.GetString((Get-Bytes $e.Open())); $ch = $false
    if ($s.Contains($bad)) { $s = $s.Replace($bad, $off); $hit++; $ch = $true }
    if ($s.Contains($sslOld) -and -not $e.FullName.StartsWith('org/tlauncher/util/TlauncherUtil')) { $s = $s.Replace($sslOld, $sslNew); $ssl++; $ch = $true }
    if ($e.FullName -eq 'org/tlauncher/util/TlauncherUtil.class' -and $s.Contains($hpOld)) { $s = $s.Replace($hpOld, $hpNew); $hpHits++; $ch = $true }
    if ($ch) {
      $nb = $latin.GetBytes($s); $nm = $e.FullName; $e.Delete()
      $o = $z.CreateEntry($nm).Open(); $o.Write($nb, 0, $nb.Length); $o.Close()
    }
  }
  Write-Host "  disabled unsafe updater link in $hit file(s); kept HTTPS checks on in $ssl file(s); clean home page: $hpHits"
  # report any other plain-http .exe link the new version might add
  foreach ($e in @($z.Entries | Where-Object { $_.FullName -like '*.class' })) {
    $s = $latin.GetString((Get-Bytes $e.Open()))
    if ($s -match 'http://[\x21-\x7e]*?\.exe') { Write-Host "  WARNING: new plain-HTTP .exe link in $($e.FullName): $($Matches[0])" -ForegroundColor Yellow }
  }
} finally { $z.Dispose() }
Remove-Item $orig

Write-Host 'Swapping in the new version...'
foreach ($n in 'TLauncher-hardened.jar','lib','javafx') {
  if (-not (Test-Path (Join-Path $stage $n))) { throw "New version is missing $n - update stopped, nothing changed." }
}
$names = 'TLauncher-hardened.jar','lib','javafx','version.txt'
$bak = Join-Path $root "backup\$cur"
if (Test-Path $bak) { Remove-Item $bak -Recurse -Force }
New-Item -ItemType Directory -Force -Path $bak | Out-Null
try {
  foreach ($n in $names) { $p = Join-Path $root $n; if (Test-Path $p) { Move-Item $p $bak } }
  foreach ($n in 'TLauncher-hardened.jar','lib','javafx') { Move-Item (Join-Path $stage $n) $root }
  Set-Content -Path (Join-Path $root 'version.txt') -Value $new -Encoding ASCII
} catch {
  Write-Host 'Swap failed - restoring the previous version.' -ForegroundColor Red
  foreach ($n in $names) {
    $p = Join-Path $root $n; $b = Join-Path $bak $n
    if (Test-Path $b) { if (Test-Path $p) { Remove-Item $p -Recurse -Force }; Move-Item $b $root }
  }
  throw
}
Remove-Item $stage -Recurse -Force
Write-Host ''
Write-Host "Updated $cur -> $new. Old version kept in backup\$cur (delete it any time)." -ForegroundColor Green
Write-Host 'Note: Java and the game files were not changed. Minecraft versions update from inside the launcher.'
