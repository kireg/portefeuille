# Quickstart: Crowdfunding Simulation

## Usage

```dart
final service = CrowdfundingService();

// 1. Get Data
final assets = assetRepository.getAll();
final transactions = transactionRepository.getAll();

// 2. Run Simulation
final simulation = service.simulateCrowdfundingEvolution(
  assets: assets,
  transactions: transactions,
);

// 3. Display in Chart
CrowdfundingProjectionChart(
  simulationData: simulation,
);
```

## Key Changes

- `CrowdfundingService` now requires `transactions` to reconstruct history.
- `CrowdfundingProjectionChart` no longer calculates logic; it just renders the `simulationData`.
