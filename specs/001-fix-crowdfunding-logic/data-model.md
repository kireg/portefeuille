# Data Model: Crowdfunding Simulation

## Entities

### CrowdfundingSimulationState
Represents the state of the crowdfunding portfolio at a specific point in time.

| Field | Type | Description |
|-------|------|-------------|
| `date` | `DateTime` | The date of this state snapshot. |
| `liquidity` | `double` | Available cash (Deposits + Returns - Investments). |
| `investedCapital` | `double` | Total capital currently invested in active projects. |
| `totalInterestsReceived` | `double` | Cumulative interests received since start. |
| `activeProjects` | `Map<String, double>` | Map of AssetID -> Remaining Capital. |

### CrowdfundingEvent
Represents a financial event in the simulation (historical or projected).

| Field | Type | Description |
|-------|------|-------------|
| `date` | `DateTime` | Date of the event. |
| `type` | `TransactionType` | Deposit, Buy, Interest, CapitalRepayment. |
| `amount` | `double` | Monetary value. |
| `assetId` | `String?` | Linked project (null for Deposit). |
| `isProjected` | `bool` | True if this is a future projection. |

## Logic Flow

1.  **Initialization**:
    - `liquidity` = 0
    - `investedCapital` = 0
    - `activeProjects` = {}

2.  **Event Processing**:
    - **Deposit**: `liquidity += amount`
    - **Buy**:
        - `liquidity -= amount`
        - `investedCapital += amount`
        - `activeProjects[assetId] += amount`
    - **Interest**:
        - `liquidity += amount`
        - `totalInterestsReceived += amount`
    - **CapitalRepayment**:
        - `liquidity += amount`
        - `investedCapital -= amount`
        - `activeProjects[assetId] -= amount`

3.  **Projection Calculation**:
    - For each active project in `activeProjects`:
        - Calculate remaining duration.
        - Generate future `Interest` events based on `activeProjects[assetId]` (remaining capital) * `yield`.
        - Generate `CapitalRepayment` at maturity.
