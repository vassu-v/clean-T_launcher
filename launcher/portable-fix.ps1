# Keeps the folder portable (USB stick, other drive letter, renamed folder).
# TLauncher stores some full paths (e.g. minecraft.gamedir). Before every start this replaces the old
# folder location with the current one in TLauncher's settings/profile files. Only files inside data\ are touched.
param([string]$Root)
$ErrorActionPreference = 'SilentlyContinue'
$root = [IO.Path]::GetFullPath($Root).TrimEnd('\')
$data = Join-Path $root 'data'
$mark = Join-Path $data '.last-root'

function PropEsc([string]$s) {   # Java .properties escaping: \ -> \\, : -> \:, non-ASCII -> \uXXXX
  $sb = New-Object Text.StringBuilder
  foreach ($c in $s.ToCharArray()) {
    if ($c -eq '\') { [void]$sb.Append('\\') } elseif ($c -eq ':') { [void]$sb.Append('\:') }
    elseif ([int]$c -gt 126) { [void]$sb.Append(('\u{0:x4}' -f [int]$c)) } else { [void]$sb.Append($c) }
  }
  $sb.ToString()
}
function Swap([string]$text, [string]$from, [string]$to) {
  [regex]::Replace($text, [regex]::Escape($from), { param($m) $to }, 'IgnoreCase')
}

$props = Join-Path $data '.tlauncher\tlauncher-2.0.properties'
$jsons = @((Join-Path $data '.minecraft\TlauncherProfiles.json'), (Join-Path $data '.minecraft\launcher_profiles.json'))
$old = $null
if (Test-Path $mark) { $old = (Get-Content $mark -Raw).Trim() }

if ($old -and $old -ine $root) {
  foreach ($f in @($props) + $jsons) {
    if (-not (Test-Path $f)) { continue }
    $t = [IO.File]::ReadAllText($f)
    $t = Swap $t (PropEsc $old) (PropEsc $root)                 # properties form  C\:\\Games\\...
    $t = Swap $t ($old.Replace('\','\\')) ($root.Replace('\','\\')) # JSON form        C:\\Games\\...
    $t = Swap $t ($old.Replace('\','/')) ($root.Replace('\','/'))   # forward slashes  C:/Games/...
    $t = Swap $t $old $root                                       # plain form
    [IO.File]::WriteAllText($f, $t)
  }
}

# the game folder always lives in data\.minecraft of the CURRENT location
if (Test-Path $props) {
  $want = 'minecraft.gamedir=' + (PropEsc (Join-Path $data '.minecraft'))
  $lines = [IO.File]::ReadAllLines($props)
  $found = $false
  for ($i = 0; $i -lt $lines.Length; $i++) { if ($lines[$i].StartsWith('minecraft.gamedir=')) { $lines[$i] = $want; $found = $true } }
  if ($found) { [IO.File]::WriteAllLines($props, $lines) }
}
New-Item -ItemType Directory -Force -Path $data | Out-Null
[IO.File]::WriteAllText($mark, $root)
