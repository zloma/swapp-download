# Recomputes the CSP script hash in index.html and i/index.html.
# Run after ANY edit to an inline <script>:  powershell -File tool/csp-hash.ps1
# Use -Check to only verify (exit 1 on mismatch).
param([switch]$Check)
$root = Split-Path -Parent $PSScriptRoot
$bad = $false
foreach ($rel in @('index.html', 'i/index.html')) {
  $file = Join-Path $root $rel
  $html = [IO.File]::ReadAllText($file, [Text.Encoding]::UTF8)
  $m = [regex]::Match($html, '<script>([\s\S]*?)</script>')
  if (-not $m.Success) { Write-Error "${rel}: no inline script"; $bad = $true; continue }
  $sha = [Security.Cryptography.SHA256]::Create()
  $hash = [Convert]::ToBase64String($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($m.Groups[1].Value)))
  $want = "'sha256-$hash'"
  $csp = [regex]::Match($html, "script-src ('sha256-[^']*')")
  if (-not $csp.Success) { Write-Error "${rel}: no script-src hash in CSP"; $bad = $true; continue }
  if ($csp.Groups[1].Value -eq $want) { Write-Host "${rel}: ok"; continue }
  if ($Check) { Write-Error "${rel}: hash MISMATCH"; $bad = $true; continue }
  $html = $html.Replace($csp.Groups[1].Value, $want)
  [IO.File]::WriteAllText($file, $html, (New-Object Text.UTF8Encoding($false)))
  Write-Host "${rel}: updated"
}
if ($bad) { exit 1 }
