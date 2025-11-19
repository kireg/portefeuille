# Validate unique numeric prefixes under lib/features
# Exits with code 0 when no duplicates found; 1 when duplicates exist

$features = Get-ChildItem -Directory -Path .\lib\features\* -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
$prefixes = @{}
foreach ($f in $features) {
  if ($f -match '^(\d{2})_') {
    $p = $matches[1]
    if (-not $prefixes.ContainsKey($p)) { $prefixes[$p] = @() }
    $prefixes[$p] += $f
  }
}
$dups = $prefixes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

if ($dups.Count -gt 0) {
  Write-Host "DUPLICATE_PREFIXES_FOUND"
  foreach ($d in $dups) {
    Write-Host ("Prefix {0} used by: {1}" -f $d.Key, ($d.Value -join ', '))
  }
  exit 1
}

Write-Host "OK: No duplicate feature numeric prefixes found."
exit 0

