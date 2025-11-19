# Feature: Modifications-avec-SpecKit

## Overview / Context
Cette feature ajoute l'infrastructure de spécification (SpecKit) et fournit les artefacts `spec.md`, `plan.md` et `tasks.md` nécessaires pour documenter, planifier et exécuter les modifications demandées dans le dépôt.

Elle sert surtout à :
- standardiser la création de specs pour les nouvelles features,
- garantir la conformité à la constitution du projet,
- fournir un mapping clair exigences ↔ tâches pour l'implémentation et les revues.

## Functional Requirements
1. user-can-generate-feature-structure
   - Description: L'utilisateur peut générer une arborescence de feature contenant `spec.md`, `plan.md`, `tasks.md` via l'outil SpecKit.
2. spec-files-present-for-feature
   - Description: Chaque feature a un dossier `specs/<feature-name>/` contenant les 3 fichiers requis.
3. tasks-map-to-requirements
   - Description: Chaque exigence fonctionnelle doit avoir au moins une tâche associée dans `tasks.md`.
4. feature-numbering-unique
   - Description: Les features sont numérotées 00-99 et les préfixes numériques doivent être uniques dans `lib/features/`.
5. constitution-compliance-checked
   - Description: Le processus de revue valide automatiquement les règles non-négociables de la constitution (ex: accès Hive, placement dans `core/`).
6. providers-not-duplicated
   - Description: Les providers globaux (ex: `PortfolioProvider`) ne doivent pas être dupliqués dans une feature.
7. hive-access-via-repository
   - Description: Aucune feature n'accède directement à Hive; accès via repository/provider.
8. ui-imports-use-core-widgets
   - Description: Les composants UI réutilisables doivent être importés depuis `core/ui/widgets/` lorsque réutilisés par 2+ features.
9. migration-tests-for-hive-schema
   - Description: Toute modification de schéma Hive doit inclure des tests de migration automatisés.

## Non-Functional Requirements
1. nfr-spec-generation-time
   - Description: La génération des fichiers de spec doit réussir en < 10s dans un environnement local raisonnable (CI non compté).
2. nfr-language
   - Description: Les artefacts de spécification seront en français (par convention du dépôt) et encodés en UTF-8.
3. nfr-test-first
   - Description: Modifications critiques (schéma Hive, calculs financiers) doivent suivre le principe "tests-first".
4. nfr-lintable
   - Description: Les fichiers `spec.md`/`plan.md`/`tasks.md` doivent être parsables par les scripts de CI (pas de placeholders non gérés comme TODO/???).
5. nfr-performance-budget
   - Description: Les contrôles et scripts ajoutés (validate-feature-numbering, validate-hive-access) doivent s'exécuter en moins de 5s dans CI.

## User Stories
US-01 (user-can-generate-feature-structure)
- En tant que mainteneur, je veux pouvoir créer la structure de spec (spec.md, plan.md, tasks.md) pour une nouvelle feature afin d'initier le cycle Speckit.
- Acceptance Criteria:
  - `check-prerequisites.ps1` retourne SUCCESS et liste les trois fichiers.
  - Les fichiers contiennent les sections minimales (Overview, Requirements, User Stories/Tasks).

US-02 (feature-numbering-unique)
- En tant que release manager, je veux que la numérotation des features soit unique afin d'éviter les collisions et respecter la constitution.
- Acceptance Criteria:
  - Un script de validation détecte les doublons de préfixe (ex: `05_`) et échoue la CI si des collisions sont trouvées.

US-03 (tasks-map-to-requirements)
- En tant que développeur, je veux voir pour chaque exigence au moins une tâche associée afin de savoir quoi implémenter.
- Acceptance Criteria:
  - `tasks.md` liste des Task IDs référencés par exigence (format `REQ_KEY -> TASK_ID`).

US-04 (no-direct-hive-access)
- En tant qu'architecte, je veux m'assurer qu'aucune feature n'accède directement à Hive afin de préserver l'abstraction repository/provider.
- Acceptance Criteria:
  - Un scan statique ne trouve aucune occurrence de `Hive.box` dans `lib/features/*`.

US-05 (shared-ui-in-core)
- En tant que UI engineer, je veux que les widgets réutilisés soient placés dans `core/ui/widgets/` pour éviter duplications.
- Acceptance Criteria:
  - Tout widget importé par 2+ features réside dans `core/ui/widgets/`.

## Current Application Progress
- Features present (lib/features/):
  - `00_app` (app providers, services)
  - `01_launch` (splash/wizard)
  - `02_dashboard` (overview/dashboard widgets)
  - `03_overview`
  - `04_journal`
  - `05_planner`
  - `06_settings` (or `06_settings` equivalent)
  - `07_management` (transaction/account management)
  - `08_reports` (renamed from `05_reports` — confirmed)

- Notes on progress:
  - The repository already implements Hive access in `core/data/repositories` and `core/data/services` (expected per architecture). See `core/data/repositories/portfolio_repository.dart` and `core/data/services/backup_service.dart`.
  - No direct `Hive.box` usage was found in `lib/features/` during initial scan (see acceptance criteria US-04). Scans are included in tasks to ensure ongoing compliance.

## Known Implementation Constraints / Risks
- Risk R1: IDE metadata (`.idea/workspace.xml`) may still reference renamed folders; these should be updated or ignored by CI validations (warnings only).
- Risk R2: If contributors directly reference old `05_*` paths in PRs, the numbering validator may flag false positives until imports are fixed.
- Risk R3: Migration tests for Hive schema changes must be created before altering type adapters (see `migration-tests-for-hive-schema`).

## Acceptance / Exit Criteria
- All functional requirements have tasks mapped in `tasks.md`.
- Validators (`validate-feature-numbering`, `validate-hive-access`) run in CI and return no errors on the current main branch.
- No `Hive.box` calls exist in `lib/features/` (only in core/repositories/services).
- Repository metadata referencing old paths are either updated or explicitly ignored by validators.

## Edge Cases
- EC-01: Dossier `specs/` absent ou renommé → `check-prerequisites` doit retourner une erreur claire.
- EC-02: Préfixes de features dupliqués (ex: deux dossiers `05_*`) → script de validation doit signaler et proposer renumérotation.
- EC-03: Placeholders non remplacés (`TODO`, `TKTK`) doivent être interdits pour les champs obligatoires.
- EC-04: Références IDE (.idea) ou historique Git contenant anciens noms de dossiers → doivent être ignorées par les validations, mais signalées comme warnings.

## Notes
- Cette spec respecte la constitution (Feature-First) : la feature est autonome et la structure attendue est `specs/Modifications-avec-SpecKit/`.
- Les slugs de requirements (keys) sont fournis pour faciliter le mapping automatique dans `tasks.md`.
