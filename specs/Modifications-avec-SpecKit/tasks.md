# Tasks: Modifications-avec-SpecKit

## Phase 1 — Initialize spec files and validation scripts

- T1 [P0]
  - ID: T1
  - Title: create-spec-files
  - Description: Create `spec.md`, `plan.md`, and `tasks.md` for the feature `Modifications-avec-SpecKit` and ensure they pass `check-prerequisites.ps1`.
  - Files: `specs/Modifications-avec-SpecKit/spec.md`, `specs/Modifications-avec-SpecKit/plan.md`, `specs/Modifications-avec-SpecKit/tasks.md`
  - DependsOn: []

- T2 [P0]
  - ID: T2
  - Title: add-check-prereqs-ci-entry
  - Description: Add CI job or script hook to run `.specify/scripts/powershell/check-prerequisites.ps1` before speckit tasks.
  - Files: `.github/workflows/ci.yml` (suggested)
  - DependsOn: [T1]

## Phase 1.5 — Repo consistency (post-rename)

- T1.5 [P0]
  - ID: T1.5
  - Title: scan-old-prefixes-and-ide-metadata
  - Description: Scan the repository for occurrences of the old prefix `05_reports` and for IDE metadata referencing old paths; report occurrences and, if safe, update references to `08_reports`.
  - Files: `.idea/workspace.xml`, `lib/features/08_reports/README.md`, any matched files
  - DependsOn: [T1]

## Phase 2 — Implement SpecKit generation (optional)

- T3 [P1]
  - ID: T3
  - Title: implement-speckit-specify-agent
  - Description: Implement or wire the `speckit.specify` agent to create feature spec skeletons automatically.
  - Files: `.github/prompts/speckit.specify.prompt.md`, `.specify/scripts/`
  - DependsOn: [T1]

## Phase 3 — Constitution checks

- T4 [P1]
  - ID: T4
  - Title: validate-feature-numbering
  - Description: Implement a script that scans `lib/features/` for duplicate numeric prefixes and fails CI on duplicates.
  - Files: `.specify/scripts/validate-feature-numbering.ps1`
  - DependsOn: [T1]

- T5 [P1]
  - ID: T5
  - Title: validate-no-hive-in-features
  - Description: Implement a lint/check that detects direct calls to `Hive.box` in feature code and produce a CSV or JSON report with file paths.
  - Files: `.specify/scripts/validate-hive-access.ps1`
  - DependsOn: [T1]

- T6 [P1]
  - ID: T6
  - Title: detect-shared-widgets
  - Description: Implement a script to find widgets used by 2+ features and suggest moving them to `core/ui/widgets/`.
  - Files: `.specify/scripts/detect-shared-widgets.ps1`
  - DependsOn: [T1]

## Phase 4 — Integrate with existing app state

- T7 [P1]
  - ID: T7
  - Title: validate-providers-usage
  - Description: Scan features to ensure no duplication of global providers (e.g., `PortfolioProvider`) and that features use `00_app/providers`.
  - Files: `.specify/scripts/validate-providers.ps1`
  - DependsOn: [T1, T4]

## Phase 5 — Tests & Documentation

- T6.1 [P1]
  - ID: T6.1
  - Title: add-check-prereqs-tests
  - Description: Add unit/integration tests for the `check-prerequisites` script to ensure it behaves as expected in CI.
  - Files: `test/specs/check_prereqs_test.dart`
  - DependsOn: [T1, T4, T5]

- T8 [P1]
  - ID: T8
  - Title: add-specs-readme
  - Description: Add `README.md` to `specs/Modifications-avec-SpecKit/` explaining how to use/update the spec files and run validators locally.
  - Files: `specs/Modifications-avec-SpecKit/README.md`
  - DependsOn: [T1]


## Mapping (Requirements -> Tasks)
- user-can-generate-feature-structure -> T1, T3
- spec-files-present-for-feature -> T1, T2
- tasks-map-to-requirements -> T1, T6.1
- feature-numbering-unique -> T4, T1.5
- constitution-compliance-checked -> T4, T5, T6, T7
- providers-not-duplicated -> T7
- hive-access-via-repository -> T5
- ui-imports-use-core-widgets -> T6
- migration-tests-for-hive-schema -> (requires new task when schema change is planned)
