# Feature Specification: Fix Crowdfunding Logic and UI

**Feature Branch**: `001-fix-crowdfunding-logic`  
**Created**: 2025-11-22  
**Status**: Draft  
**Input**: User description: "vérifie toute la fonctionnalité de crowdfunding. En particulier, je veux pouvoir me déplacer horizonatlement dans les projeections Crowdfunding. Et il faut revoir la logique de calcul dans la Projection Capital et intérets du crowdfunding. Schématiquement : on fait un dépot (liquidités du compte augmentées), avec ce dépot, on achete un projet qui a un certain rendement et un certain mode d'intérets, quand des intérets sont payés, ils sont ajoutés aux liquidités du compte, si c'est un remboursement de capital, il est aussi crédité sur les liquidités du compte et si c'est un remboursement partiel de liquidités, alors les intérets suivants doivent etre recalculés sur le montant restant."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Horizontal Scrolling in Projections (Priority: P1)

The user needs to be able to view financial projections over a long timeline, which requires horizontal scrolling to see future months/years that don't fit on the screen.

**Why this priority**: Essential usability requirement; without it, the user cannot view the full projection data.

**Independent Test**: Can be fully tested by navigating to the Crowdfunding Projections screen and attempting to scroll the data table/chart horizontally.

**Acceptance Scenarios**:

1. **Given** the user is on the Crowdfunding Projections screen, **When** the projection data exceeds the screen width, **Then** the user can scroll horizontally to view the hidden data.
2. **Given** the user scrolls horizontally, **When** they reach the end of the data, **Then** the scrolling stops (no infinite scroll or visual glitches).

---

### User Story 2 - Deposit and Project Purchase Flow (Priority: P1)

The user adds funds to their account (Deposit) and uses those funds to invest in projects. This flow must correctly update the account liquidity.

**Why this priority**: This is the fundamental entry point for the crowdfunding feature.

**Independent Test**: Can be tested by performing a deposit and then a purchase, verifying the liquidity balance at each step.

**Acceptance Scenarios**:

1. **Given** a user with 0€ liquidity, **When** they record a deposit of 1000€, **Then** the Account Liquidity updates to 1000€.
2. **Given** a user with 1000€ liquidity, **When** they purchase a project for 500€, **Then** the Account Liquidity decreases to 500€ and the Invested Capital increases by 500€.
3. **Given** a user with insufficient liquidity (e.g., 100€), **When** they try to purchase a project for 500€, **Then** the system prevents the transaction or shows a warning.

---

### User Story 3 - Interest and Capital Repayment Logic (Priority: P1)

The system must correctly calculate and credit interest payments and capital repayments to the account liquidity over time.

**Why this priority**: Ensures the financial projections and actual account state are accurate.

**Independent Test**: Can be tested by simulating the passage of time or triggering specific payment events for an active project.

**Acceptance Scenarios**:

1. **Given** an active project with a scheduled interest payment of 50€, **When** the payment date arrives (or is simulated), **Then** the Account Liquidity increases by 50€.
2. **Given** an active project with a scheduled capital repayment of 1000€, **When** the repayment date arrives, **Then** the Account Liquidity increases by 1000€ and the Invested Capital decreases by 1000€.

---

### User Story 4 - Partial Repayment Recalculation (Priority: P2)

When a project repays only part of the capital, the future interest calculations must be adjusted to reflect the lower outstanding capital.

**Why this priority**: Critical for accuracy in real-world scenarios where projects amortize or make partial repayments.

**Independent Test**: Can be tested by creating a project with partial repayment terms and verifying the subsequent interest amounts.

**Acceptance Scenarios**:

1. **Given** a project with 1000€ initial capital and 10% annual yield (100€/year interest), **When** a partial capital repayment of 500€ occurs, **Then** the Account Liquidity increases by 500€.
2. **Given** the partial repayment of 500€ has occurred, **When** the next interest payment is calculated, **Then** the interest amount is based on the remaining 500€ capital (e.g., 50€ instead of 100€).

### Edge Cases

- What happens when a project defaults? (Not in scope for this fix, but good to note)
- How does the system handle rounding errors in interest calculations? (Should use standard financial rounding)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Crowdfunding Projections view MUST support horizontal scrolling to display time-series data.
- **FR-002**: The system MUST allow users to record "Deposit" transactions which increase "Account Liquidity".
- **FR-003**: The system MUST allow users to record "Project Purchase" transactions which decrease "Account Liquidity" and increase "Invested Capital".
- **FR-004**: Interest payments from projects MUST be credited to "Account Liquidity".
- **FR-005**: Capital repayments from projects MUST be credited to "Account Liquidity" and decrease "Invested Capital".
- **FR-006**: The system MUST recalculate future interest payments whenever a partial capital repayment occurs, based on the remaining outstanding capital.
- **FR-007**: The system MUST display the "Account Liquidity" balance in the Crowdfunding dashboard/overview.

### Key Entities *(include if feature involves data)*

- **Account Liquidity**: The cash balance available in the crowdfunding account for new investments or withdrawal.
- **Project**: An investment entity with properties: Total Capital, Yield (%), Interest Mode (e.g., Monthly, Yearly, At Maturity), Start Date, Duration.
- **Transaction**: A financial event linked to the crowdfunding account (Deposit, Withdrawal, Purchase, Interest Payment, Capital Repayment).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can scroll horizontally to view at least 5 years of projection data.
- **SC-002**: Account Liquidity calculation is 100% accurate based on the sequence of deposits, purchases, and repayments (verified by unit tests).
- **SC-003**: Interest recalculation after partial repayment matches the expected mathematical formula (verified by unit tests).
