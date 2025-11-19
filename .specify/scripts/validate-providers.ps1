# Validate that global providers are used from 00_app/providers and not duplicated across features
$providerPattern = 'class\s+(\w+Provider)\s+extends\s+ChangeNotifier'
$allDart = Get-ChildItem -Recurse -Path .\lib -Include *.dart -ErrorAction SilentlyContinue
$providerDefs = @{}
foreach ($f in $allDart) {
  $content = Get-Content -Raw -Path $f.FullName
  foreach ($m in [regex]::Matches($content, $providerPattern)) {
    $p = $m.Groups[1].Value
    if (-not $providerDefs.ContainsKey($p)) { $providerDefs[$p] = @() }
    $providerDefs[$p] += $f.FullName
  }
}
$duplicates = $providerDefs.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($duplicates.Count -gt 0) {
  Write-Host "PROVIDER_DUPLICATES_FOUND"
  foreach ($d in $duplicates) { Write-Host "$($d.Key) defined in: $($d.Value -join ', ')" }
  exit 1
}
Write-Host "OK: No duplicated global provider classes detected."
exit 0

