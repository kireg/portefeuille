# Detect widgets imported/used by 2+ features (heuristic)
# Lists widget files referenced in imports across features

$featureDirs = Get-ChildItem -Directory -Path .\lib\features\* -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
$importMap = @{}
foreach ($dir in $featureDirs) {
  $dartFiles = Get-ChildItem -Recurse -Path $dir -Include *.dart -ErrorAction SilentlyContinue
  foreach ($f in $dartFiles) {
    $content = Get-Content -Raw -Path $f.FullName
    foreach ($m in [regex]::Matches($content, "import\s+'package:portefeuille/(.*?)';")) {
      $imp = $m.Groups[1].Value
      if ($imp -like 'core/ui/widgets/*') {
        if (-not $importMap.ContainsKey($imp)) { $importMap[$imp]=@() }
        $importMap[$imp] += $dir
      }
    }
  }
}
$shared = $importMap.GetEnumerator() | Where-Object { ($_.Value | Select-Object -Unique).Count -gt 1 }
if ($shared.Count -eq 0) { Write-Host "OK: No shared widgets detected via import heuristic."; exit 0 }
Write-Host "SHARED_WIDGETS_DETECTED"
foreach ($s in $shared) {
  Write-Host "Widget: $($s.Key) used by features: $((($s.Value | Select-Object -Unique) -join ', '))"
}
exit 1

