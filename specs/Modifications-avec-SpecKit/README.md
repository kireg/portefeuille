# Modifications-avec-SpecKit

Ce dossier contient les artefacts de spécification et les scripts de validation pour la feature "Modifications-avec-SpecKit".

## Files
- `spec.md` — spécification fonctionnelle
- `plan.md` — plan et phases
- `tasks.md` — liste des tâches et mapping requirements→tasks

## Validators (PowerShell)
Scripts disponibles sous `.specify/scripts/` :
- `check-prerequisites.ps1` — script principal (existant) qui vérifie la présence du dossier feature et `tasks.md`.
- `validate-feature-numbering.ps1` — détecte préfixes numériques dupliqués dans `lib/features/`.
- `validate-hive-access.ps1` — vérifie qu'aucune feature n'appelle `Hive.box` directement.
- `detect-shared-widgets.ps1` — heuristique pour détecter widgets partagés importés par 2+ features.
- `validate-providers.ps1` — recherche de duplications de classes Provider.

## How to run locally (PowerShell)
From the repository root:

```powershell
# check prerequisites
.\.specify\scripts\powershell\check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks

# run validators
.\.specify\scripts\validate-feature-numbering.ps1
.\.specify\scripts\validate-hive-access.ps1
.\.specify\scripts\detect-shared-widgets.ps1
.\.specify\scripts\validate-providers.ps1
```

## Next actions
- Implement CI job that runs these validators on PRs (see `plan.md` CI example).
- Review `.idea/workspace.xml` entry referencing old path `05_reports` and either update or add `.idea/` to ignore list in validators.
- Create migration tests for any planned Hive schema changes.


