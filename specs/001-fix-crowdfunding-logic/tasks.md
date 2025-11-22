# Tasks: Fix Crowdfunding Logic and UI

**Feature Branch**: `001-fix-crowdfunding-logic`
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

## Phase 1: Setup

- [x] T001 Create test file `test/features/00_app/services/crowdfunding_service_test.dart`

## Phase 2: Foundational

- [x] T002 Define `CrowdfundingSimulationState` and `CrowdfundingEvent` classes in `lib/features/00_app/services/crowdfunding_service.dart`
- [x] T003 Implement `simulateCrowdfundingEvolution` method signature in `lib/features/00_app/services/crowdfunding_service.dart`

## Phase 3: User Story 2 - Deposit and Project Purchase Flow (P1)

**Goal**: Ensure deposits increase liquidity and purchases decrease liquidity/increase invested capital.

- [x] T004 [US2] Implement logic for `TransactionType.Deposit` in `simulateCrowdfundingEvolution` in `lib/features/00_app/services/crowdfunding_service.dart`
- [x] T005 [US2] Implement logic for `TransactionType.Buy` in `simulateCrowdfundingEvolution` in `lib/features/00_app/services/crowdfunding_service.dart`
- [x] T006 [US2] Add unit tests for Deposit and Purchase flows in `test/features/00_app/services/crowdfunding_service_test.dart`

## Phase 4: User Story 3 - Interest and Capital Repayment Logic (P1)

**Goal**: Ensure interest and capital repayments are correctly credited to liquidity.

- [x] T007 [US3] Implement logic for `TransactionType.Interest` (Historical) in `lib/features/00_app/services/crowdfunding_service.dart`
- [x] T008 [US3] Implement logic for `TransactionType.CapitalRepayment` (Historical) in `lib/features/00_app/services/crowdfunding_service.dart`
- [x] T009 [US3] Implement Future Projection logic for Interest and Repayment in `lib/features/00_app/services/crowdfunding_service.dart`
- [x] T010 [US3] Add unit tests for Interest and Capital Repayment flows in `test/features/00_app/services/crowdfunding_service_test.dart`

## Phase 5: User Story 4 - Partial Repayment Recalculation (P2)

**Goal**: Ensure future interest is recalculated based on remaining capital after partial repayment.

- [x] T011 [US4] Refine projection logic to use dynamic remaining capital in `lib/features/00_app/services/crowdfunding_service.dart`
- [x] T012 [US4] Add unit tests for Partial Repayment scenarios in `test/features/00_app/services/crowdfunding_service_test.dart`

## Phase 6: User Story 1 - Horizontal Scrolling in Projections (P1)

**Goal**: Enable horizontal scrolling for long-term projections.

- [x] T013 [US1] Update `CrowdfundingProjectionChart` to accept `List<CrowdfundingSimulationState>` in `lib/features/05_planner/ui/widgets/crowdfunding_projection_chart.dart`
- [x] T014 [US1] Implement horizontal scrolling and dynamic width calculation in `lib/features/05_planner/ui/widgets/crowdfunding_projection_chart.dart`
- [x] T015 [US1] Map simulation data to chart points in `lib/features/05_planner/ui/widgets/crowdfunding_projection_chart.dart`

## Dependencies

1.  **Phase 2 (Foundational)** must be completed first.
2.  **Phase 3, 4, 5** (Logic) should be completed before **Phase 6** (UI) to ensure data is available.
3.  **Phase 3, 4, 5** can be implemented sequentially or in parallel, but Phase 5 depends on the basic projection logic of Phase 4.

## Implementation Strategy

1.  **TDD Approach**: For Phases 3, 4, and 5, write the unit tests (T006, T010, T012) *before* or *alongside* the implementation to verify the complex financial logic.
2.  **UI Integration**: Once the service logic is solid and tested, wire it up to the UI in Phase 6.
