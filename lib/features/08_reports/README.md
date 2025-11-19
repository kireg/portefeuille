# Feature 08_reports

## Description
Feature dédiée à la génération et à l'affichage des rapports financiers détaillés.

## Structure

```
05_reports/
├── ui/
│   ├── reports_screen.dart            # Écran principal des rapports
│   └── widgets/
│       ├── report_card.dart           # Widget pour les cartes de rapport
│       └── export_button.dart         # Widget pour les boutons d'export
```

## Responsabilités

- **ReportsScreen** : Conteneur principal pour les widgets de rapports
- **ReportCard** : Affiche un résumé des rapports financiers
- **ExportButton** : Permet l'exportation des rapports

## Règles de conformité

✅ **Autorisé** :
- Widgets spécifiques aux rapports
- Logique UI pour afficher et exporter les rapports

❌ **Interdit** :
- Logique métier (doit être dans Core ou 00_app)
- Dépendances directes aux autres features

## Dépendances

- ✅ Importe : Core, Providers globaux (PortfolioProvider, SettingsProvider)
- ❌ N'importe PAS : Autres features

---

**Dernière mise à jour** : Phase 4 Audit | Constitution v1.0.0

