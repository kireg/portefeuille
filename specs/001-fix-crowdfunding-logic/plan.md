# Implementation Plan: Fix Crowdfunding Logic and UI

**Branch**: `001-fix-crowdfunding-logic` | **Date**: 2025-11-22 | **Spec**: [link](spec.md)
**Input**: Feature specification from `/specs/001-fix-crowdfunding-logic/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a full simulation engine for Crowdfunding to correctly track Account Liquidity, Invested Capital, and Interest Payments over time (past and future). Fix the `Asset.quantity` logic to account for Capital Repayments. Update the `CrowdfundingProjectionChart` to use this simulation data and ensure horizontal scrolling works correctly.

## Technical Context

**Language/Version**: Dart 3.4+ / Flutter 3.22+
**Primary Dependencies**: Provider, Hive, fl_chart
**Storage**: Hive (local DB)
**Testing**: flutter_test
**Target Platform**: Windows, Android, iOS, Linux, macOS, Web
**Project Type**: Mobile/Desktop/Web
**Performance Goals**: 60 fps UI, responsive scrolling
**Constraints**: Offline-capable, strict architecture rules
**Scale/Scope**: Feature-based architecture

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Architecture Feature-First**: Logic will be in `00_app/services` (shared) and `05_planner` (UI).
- **Hiérarchie des Dépendances**: `05_planner` -> `00_app`. OK.
- **Principe de Responsabilité Unique**: New `CrowdfundingSimulation` logic.
- **Ressources Partagées dans Core**: Models in `core/data/models`.

## Project Structure

### Documentation (this feature)

```text
specs/001-fix-crowdfunding-logic/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── features/
│   ├── 00_app/
│   │   └── services/
│   │       └── crowdfunding_service.dart  # Update logic
│   └── 05_planner/
│       └── ui/
│           └── widgets/
│               └── crowdfunding_projection_chart.dart # Update UI
```

**Structure Decision**: Modify existing files in `00_app` and `05_planner`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
