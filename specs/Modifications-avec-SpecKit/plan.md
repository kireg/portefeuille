# Plan: Modifications-avec-SpecKit

## Architecture / Stack Choices
- Language: Dart / Flutter (existing project)
- State management: Provider (conformément à la constitution)
- Persistence: Hive via `PortfolioRepository` (features must not access Hive directly)
- Tooling: SpecKit scripts under `.specify/scripts/` for prereqs and validation

## Data Model References
- Use existing domain models under `core/data/models/` where applicable
- Any new model must include Hive typeAdapters and migration tests
- Cross-feature models: verify usage in `lib/features/00_app`, `lib/features/02_dashboard`, `lib/features/04_journal`, `lib/features/07_management`, `lib/features/08_reports` and move shared models to `core/data/models/`.

## Phases
1. Phase 1 — Initialize spec files and validation scripts
   - Create `spec.md`, `plan.md`, `tasks.md` (this step)
   - Add CI script entrypoint to run `check-prerequisites.ps1`
   - Minimal validation: feature directory existence, `tasks.md` presence
2. Phase 2 — Implement SpecKit generation logic (optional)
   - Implement or wire `/speckit.specify` agent to create templates
   - Provide a CLI helper to scaffold `specs/<feature-name>/` from prompts
3. Phase 3 — Enforce constitution checks in CI
   - Validate feature numbering uniqueness, provider duplication, and Hive access rules
   - Add script to detect widgets used by 2+ features and suggest move to `core/ui/widgets/`
   - Add script to scan for `Hive.box` usage and list offending files
4. Phase 4 — Integrate with existing app state
   - Ensure `00_app/providers/` exposes `PortfolioProvider` and `SettingsProvider` for features
   - Validate that features `07_management` and `08_reports` consume providers without duplicating them
5. Phase 5 — Documentation & tests
   - Add unit/integration tests for validation scripts
   - Add README in `specs/Modifications-avec-SpecKit/` with how-to for maintainers

## Technical Constraints
- Must conform to `.specify/memory/constitution.md` (feature-first, numbering, providers rules)
- No direct Hive access from feature UI
- All files must be UTF-8 encoded French Markdown
- Validation scripts should avoid scanning `.idea/` and `build/` directories by default

## CI Example (GitHub Actions)
- Job: `validate-specs`
  - Runs on: pull_request
  - Steps:
    - Checkout
    - Run PowerShell: `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks`
    - Run feature-numbering validator script
    - Run `validate-hive-access.ps1`

## Success Criteria
- `check-prerequisites.ps1` reports success with `FEATURE_DIR` and lists `spec.md`, `plan.md`, `tasks.md`.
- No duplicated feature-number prefixes in `lib/features/`.
- All functional requirements have at least one task in `tasks.md`.
- Validation scripts do not produce false positives due to IDE metadata files.
