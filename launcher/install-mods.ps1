# Installs the mods listed in mods-list.txt from Modrinth (the official mod site) into this folder only.
# Every file is checked against Modrinth's SHA-512 fingerprint. Old versions of the same mod are moved to mods-old.
param([string]$McVersion = '', [string]$Loader = 'fabric')
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
$root = $PSScriptRoot
$mods = Join-Path $root 'data\.minecraft\mods'
$old  = Join-Path $root 'data\.minecraft\mods-old'
New-Item -ItemType Directory -Force -Path $mods | Out-Null
$ua = 'hardened-tlauncher-mod-installer/1.0'

if (-not $McVersion) {
  $guess = ''
  $vdir = Join-Path $root 'data\.minecraft\versions'
  if (Test-Path $vdir) {
    $f = Get-ChildItem $vdir -Directory | Where-Object { $_.Name -match 'fabric' -and $_.Name -match '1\.\d+' } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($f) { $guess = ([regex]::Matches($f.Name, '1\.\d+(\.\d+)?') | Select-Object -Last 1).Value }
  }
  $ans = Read-Host "Minecraft version for the mods [$guess]"
  $McVersion = if ($ans) { $ans.Trim() } else { $guess }
  if (-not $McVersion) { throw 'No Minecraft version given. Install a Fabric version in TLauncher first, or type one (e.g. 1.21.4).' }
}
Write-Host "Installing $Loader mods for Minecraft $McVersion"

$list = Get-Content (Join-Path $root 'mods-list.txt') | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') }
$failed = @()
foreach ($slug in $list) {
  $q = 'game_versions=' + [uri]::EscapeDataString("[""$McVersion""]") + '&loaders=' + [uri]::EscapeDataString("[""$Loader""]")
  try {
    $vers = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$slug/version?$q" -UserAgent $ua
  } catch { Write-Host "  $slug : lookup failed ($($_.Exception.Message))" -ForegroundColor Yellow; $failed += $slug; continue }
  $v = @($vers | Where-Object { $_.version_type -eq 'release' }) + @($vers) | Select-Object -First 1
  if (-not $v) { Write-Host "  $slug : no version for $McVersion/$Loader" -ForegroundColor Yellow; $failed += $slug; continue }
  $file = @($v.files | Where-Object { $_.primary }) + @($v.files) | Select-Object -First 1
  $dest = Join-Path $mods $file.filename
  if ((Test-Path $dest) -and (Get-FileHash $dest -Algorithm SHA512).Hash -ieq $file.hashes.sha512) { Write-Host "  $slug : up to date"; continue }
  $tmp = "$dest.part"
  try { Invoke-WebRequest -Uri $file.url -OutFile $tmp -UserAgent $ua -UseBasicParsing }
  catch { Remove-Item $tmp -ErrorAction SilentlyContinue; Write-Host "  $slug : download failed" -ForegroundColor Yellow; $failed += $slug; continue }
  if ((Get-FileHash $tmp -Algorithm SHA512).Hash -ine $file.hashes.sha512) { Remove-Item $tmp; Write-Host "  $slug : FINGERPRINT MISMATCH, skipped" -ForegroundColor Red; $failed += $slug; continue }
  # move older copies of the same mod out of the way
  $proj = $v.project_id
  foreach ($j in Get-ChildItem $mods -Filter *.jar) {
    if ($j.Name -eq $file.filename) { continue }
    try {
      $h = (Get-FileHash $j.FullName -Algorithm SHA1).Hash.ToLower()
      $info = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$h" -UserAgent $ua
      if ($info.project_id -eq $proj) { New-Item -ItemType Directory -Force -Path $old | Out-Null; Move-Item $j.FullName $old -Force; Remove-Item (Join-Path $root "mods-preset\$($j.Name)") -ErrorAction SilentlyContinue }
    } catch {}
  }
  Move-Item $tmp $dest -Force
  Write-Host "  $slug : installed $($file.filename)" -ForegroundColor Green
}
Write-Host ''
if ($failed) { Write-Host "Not installed: $($failed -join ', ')" -ForegroundColor Yellow }
Write-Host "Done. Mods are in data\.minecraft\mods. Pick the Fabric $McVersion version in TLauncher and play."
