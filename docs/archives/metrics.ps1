#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Script pour exécuter Dart Code Metrics avec différentes options d'analyse
    
.DESCRIPTION
    Automatise les commandes Dart Code Metrics pour analyser un projet Flutter/Dart
    
.EXAMPLE
    .\metrics.ps1 html     # Génère un rapport HTML
    .\metrics.ps1 analyze  # Affiche violations en console
    .\metrics.ps1 clean    # Supprime les rapports générés
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet('analyze', 'html', 'json', 'dead-code', 'complex', 'metrics', 'strict', 'clean', '')]
    [string]$Command = ''
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

function Show-Help {
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║       Dart Code Metrics - Script d'Analyse Automatisé        ║
╚═══════════════════════════════════════════════════════════════╝

USAGE: .\metrics.ps1 [commande]

COMMANDES DISPONIBLES:
  analyze     🔍  Affiche violations en console (verbose)
  html        📊  Génère rapport HTML interactif
  json        📋  Génère rapport JSON programmable
  dead-code   🗑️   Détecte le code mort uniquement
  complex     📈  Montre fonctions avec haute complexité (>10)
  metrics     📊  Affiche toutes les métriques du projet
  strict      🔴  Analyse STRICTE avec seuils renforcés
  clean       🧹  Supprime les rapports générés

EXEMPLES:
  .\metrics.ps1 html        # Génère rapport interactif
  .\metrics.ps1 analyze     # Affichage en console
  .\metrics.ps1 dead-code   # Code mort uniquement
  .\metrics.ps1 strict      # Analyse avec seuils strictes

ℹ️  Note: DCM doit être installé globalement:
   dart pub global activate dart_code_metrics
"@
}

function Invoke-MetricsAnalyze {
    Write-Host "`n🔍 Analyse en cours - Violations trouvées:`n" -ForegroundColor Cyan
    dart pub global run dart_code_metrics:metrics analyze lib -r console-verbose --no-congratulate --disable-sunset-warning
}

function Invoke-MetricsHtml {
    Write-Host "`n📊 Génération du rapport HTML...`n" -ForegroundColor Cyan
    dart pub global run dart_code_metrics:metrics analyze lib -r html -o metrics_report --disable-sunset-warning
    
    if (Test-Path 'metrics_report\index.html') {
        Write-Host "`n✅ Rapport généré avec succès!" -ForegroundColor Green
        Write-Host "   📂 Chemin: metrics_report\index.html" -ForegroundColor Green
        Write-Host "   💡 Ouvre ce fichier dans ton navigateur pour une vue interactive.`n" -ForegroundColor Yellow
    } else {
        Write-Host "`n❌ Erreur: Impossible de générer le rapport`n" -ForegroundColor Red
    }
}

function Invoke-MetricsJson {
    Write-Host "`n📋 Génération du rapport JSON...`n" -ForegroundColor Cyan
    dart pub global run dart_code_metrics:metrics analyze lib -r json --json-path=metrics_report/report.json --disable-sunset-warning
    
    if (Test-Path 'metrics_report\report.json') {
        Write-Host "`n✅ Rapport JSON généré!" -ForegroundColor Green
        Write-Host "   📂 Chemin: metrics_report\report.json`n" -ForegroundColor Green
    }
}

function Invoke-MetricsDeadCode {
    Write-Host "`n🗑️  Analyse du code mort...`n" -ForegroundColor Cyan
    $output = dart pub global run dart_code_metrics:metrics analyze lib -r console-verbose --no-congratulate --disable-sunset-warning
    
    $deadCode = $output | Select-String "lines of code: 0"
    if ($deadCode) {
        Write-Host "Code mort détecté:" -ForegroundColor Yellow
        Write-Host $deadCode -ForegroundColor White
        Write-Host "`n💡 Conseil: Supprime les méthodes/propriétés sans logique`n" -ForegroundColor Cyan
    } else {
        Write-Host "✅ Aucun code mort détecté!" -ForegroundColor Green
    }
}

function Invoke-MetricsComplex {
    Write-Host "`n📈 Fonctions avec haute complexité (>10):`n" -ForegroundColor Cyan
    $output = dart pub global run dart_code_metrics:metrics analyze lib -r console-verbose --no-catastrophe --disable-sunset-warning
    
    $complex = $output | Select-String "cyclomatic complexity: ([0-9]+)" | ForEach-Object {
        if ([int]($_ -replace '.*complexity: (\d+).*', '$1') -gt 10) {
            $_
        }
    }
    
    if ($complex) {
        Write-Host $complex
        Write-Host "`n💡 Refactorise ces fonctions pour réduire la complexité`n" -ForegroundColor Yellow
    } else {
        Write-Host "✅ Aucune fonction excessivement complexe!" -ForegroundColor Green
    }
}

function Invoke-MetricsAll {
    Write-Host "`n📊 Toutes les métriques du projet:`n" -ForegroundColor Cyan
    dart pub global run dart_code_metrics:metrics analyze lib -r console-verbose --no-congratulate --disable-sunset-warning
}

function Invoke-MetricsStrict {
    Write-Host "`n🔴 Analyse STRICTE - Seuils renforcés:`n" -ForegroundColor Red
    dart pub global run dart_code_metrics:metrics analyze lib `
        --cyclomatic-complexity=10 `
        --lines-of-code=75 `
        --maximum-nesting-level=4 `
        -r console-verbose --no-congratulate --disable-sunset-warning
}

function Invoke-MetricsClean {
    Write-Host "`n🧹 Suppression des rapports...`n" -ForegroundColor Cyan
    
    if (Test-Path 'metrics_report') {
        Remove-Item 'metrics_report' -Recurse -Force
        Write-Host "✅ Rapports supprimés avec succès!`n" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Aucun rapport à nettoyer`n" -ForegroundColor Yellow
    }
}

# Exécution
switch ($Command) {
    '' { Show-Help }
    'analyze' { Invoke-MetricsAnalyze }
    'html' { Invoke-MetricsHtml }
    'json' { Invoke-MetricsJson }
    'dead-code' { Invoke-MetricsDeadCode }
    'complex' { Invoke-MetricsComplex }
    'metrics' { Invoke-MetricsAll }
    'strict' { Invoke-MetricsStrict }
    'clean' { Invoke-MetricsClean }
}

Write-Host ""
