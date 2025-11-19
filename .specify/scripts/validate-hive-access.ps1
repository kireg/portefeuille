# Validate that no `Hive.box` calls are present under lib/features
# Exits 0 if none found; 1 if occurrences found

$excludeDirs = @('.idea','build','.git')
$files = Get-ChildItem -Recurse -Path .\lib\features -Include *.dart -ErrorAction SilentlyContinue | Where-Object { $excluded = $false; foreach ($e in $excludeDirs) { if ($_.FullName -like "*\\$e\\*") { $excluded = $true } }; -not $excluded }
$hits = @()
foreach ($f in $files) {
  $content = Get-Content -Raw -Path $f.FullName -ErrorAction SilentlyContinue
  if ($content -match 'Hive\.box') { $hits += $f.FullName }
}
if ($hits.Count -gt 0) {
  Write-Host "HIVE_USAGE_FOUND"
  $hits | ForEach-Object { Write-Host $_ }
  exit 1
}
Write-Host "OK: No Hive.box usage in lib/features"
exit 0

