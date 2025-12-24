import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/repayment_type.dart';
import 'package:portefeuille/features/00_app/services/crowdfunding_service.dart';

void main() {
  late CrowdfundingService service;

  setUp(() {
    service = CrowdfundingService();
  });

  Transaction createTransaction({
    required String id,
    required TransactionType type,
    required DateTime date,
    required double amount,
    String? assetId,
    AssetType? assetType,
  }) {
    return Transaction(
      id: id,
      accountId: 'acc_1',
      type: type,
      date: date,
      amount: amount,
      fees: 0,
      notes: '',
      assetType: assetType,
      assetTicker: assetId, // Using ticker as ID for simplicity in mock
    );
  }

  Asset createAsset({
    required String id,
    required String name,
  }) {
    return Asset(
      id: id,
      name: name,
      ticker: id,
      type: AssetType.RealEstateCrowdfunding,
      currentPrice: 1.0,
      estimatedAnnualYield: 0.0,
      priceCurrency: 'EUR',
      currentExchangeRate: 1.0,
    );
  }

  group('CrowdfundingService Simulation - Deposit & Buy', () {
    test('Deposit should increase liquidity', () {
      final transactions = [
        createTransaction(
          id: 't1',
          type: TransactionType.Deposit,
          date: DateTime(2023, 1, 1),
          amount: 1000,
          assetType: AssetType.RealEstateCrowdfunding,
        ),
      ];

      final simulation = service.simulateCrowdfundingEvolution(
        assets: [],
        transactions: transactions,
        projectionMonths: 0,
      );
      // Find state at 2023-01-01
      // Note: The simulation might return states for every month or every event.
      // We assume it returns at least one state per event date or month.
      // For now, let's check if we can find a state with the correct date.
      final state = simulation.firstWhere((s) => s.date.year == 2023 && s.date.month == 1 && s.date.day == 1);
      expect(state.liquidity, 1000);
      expect(state.investedCapital, 0);
    });

    test('Buy should decrease liquidity and increase invested capital', () {
      final asset = createAsset(id: 'p1', name: 'Project 1');
      final transactions = [
        createTransaction(
          id: 't1',
          type: TransactionType.Deposit,
          date: DateTime(2023, 1, 1),
          amount: 1000,
          assetType: AssetType.RealEstateCrowdfunding,
        ),
        createTransaction(
          id: 't2',
          type: TransactionType.Buy,
          date: DateTime(2023, 1, 2),
          amount: 500,
          assetId: 'p1',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
      ];

      final simulation = service.simulateCrowdfundingEvolution(
        assets: [asset],
        transactions: transactions,
        projectionMonths: 0,
      );

      // State after Deposit
      final state1 = simulation.firstWhere((s) => s.date.year == 2023 && s.date.month == 1 && s.date.day == 1);
      expect(state1.liquidity, 1000);

      // State after Buy
      final state2 = simulation.firstWhere((s) => s.date.year == 2023 && s.date.month == 1 && s.date.day == 2);
      expect(state2.liquidity, 500); // 1000 - 500
      expect(state2.investedCapital, 500);
    });
  });

  group('CrowdfundingService Simulation - Interest & Repayment', () {
    test('Interest should increase liquidity', () {
      final asset = createAsset(id: 'p1', name: 'Project 1');
      final transactions = [
        createTransaction(
          id: 't1',
          type: TransactionType.Deposit,
          date: DateTime(2023, 1, 1),
          amount: 1000,
          assetType: AssetType.RealEstateCrowdfunding,
        ),
        createTransaction(
          id: 't2',
          type: TransactionType.Buy,
          date: DateTime(2023, 1, 2),
          amount: 500,
          assetId: 'p1',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
        createTransaction(
          id: 't3',
          type: TransactionType.Interest,
          date: DateTime(2023, 2, 1),
          amount: 5,
          assetId: 'p1',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
      ];

      final simulation = service.simulateCrowdfundingEvolution(
        assets: [asset],
        transactions: transactions,
        projectionMonths: 0,
      );

      final state = simulation.firstWhere((s) => s.date.year == 2023 && s.date.month == 2 && s.date.day == 1);
      expect(state.liquidity, 505); // 500 (remaining) + 5 (interest)
      expect(state.cumulativeInterests, 5);
    });

    test('Capital Repayment should increase liquidity and decrease invested capital', () {
      final asset = createAsset(id: 'p1', name: 'Project 1');
      final transactions = [
        createTransaction(
          id: 't1',
          type: TransactionType.Deposit,
          date: DateTime(2023, 1, 1),
          amount: 1000,
          assetType: AssetType.RealEstateCrowdfunding,
        ),
        createTransaction(
          id: 't2',
          type: TransactionType.Buy,
          date: DateTime(2023, 1, 2),
          amount: 500,
          assetId: 'p1',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
        createTransaction(
          id: 't3',
          type: TransactionType.CapitalRepayment,
          date: DateTime(2023, 6, 1),
          amount: 500,
          assetId: 'p1',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
      ];

      final simulation = service.simulateCrowdfundingEvolution(
        assets: [asset],
        transactions: transactions,
        projectionMonths: 0,
      );

      final state = simulation.firstWhere((s) => s.date.year == 2023 && s.date.month == 6 && s.date.day == 1);
      expect(state.liquidity, 1000); // 500 + 500
      expect(state.investedCapital, 0); // 500 - 500
    });

    test('Partial Repayment should reduce future interest', () {
      // Yield 12% -> 1% per month.
      // Capital 1000 -> 10 per month.
      // Repayment 500 -> Remaining 500 -> 5 per month.

      final assetWithYield = Asset(
        id: 'p1',
        name: 'Project 1',
        ticker: 'p1',
        type: AssetType.RealEstateCrowdfunding,
        currentPrice: 1.0,
        estimatedAnnualYield: 12.0, // 12%
        expectedYield: 12.0, // Crowdfunding specific field
        priceCurrency: 'EUR',
        currentExchangeRate: 1.0,
        targetDuration: 12, // 1 year
        repaymentType: RepaymentType.MonthlyInterest,
      );

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 10)); // Started 10 days ago

      final transactionsRecent = [
        createTransaction(
          id: 't1',
          type: TransactionType.Deposit,
          date: startDate,
          amount: 1000,
          assetType: AssetType.RealEstateCrowdfunding,
        ),
        createTransaction(
          id: 't2',
          type: TransactionType.Buy,
          date: startDate,
          amount: 1000,
          assetId: 'p1',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
        createTransaction(
          id: 't3',
          type: TransactionType.CapitalRepayment,
          date: startDate.add(const Duration(days: 1)),
          amount: 500,
          assetId: 'p1',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
      ];

      final simulation = service.simulateCrowdfundingEvolution(
        assets: [assetWithYield],
        transactions: transactionsRecent,
        projectionMonths: 12,
      );

      // Check if there is ANY state where liquidity is 1000 (deposit) - 1000 (buy) + 500 (repayment) + 5 (interest) = 505.
      // This confirms that the interest was calculated as 5 (based on 500 capital) and not 10 (based on 1000 capital).
      final hasCorrectInterest = simulation.any((s) => (s.liquidity - 505).abs() < 0.01);
      expect(hasCorrectInterest, isTrue);
    });
  });

  group('CrowdfundingService duration basis (max vs target)', () {
    test('generateProjections uses maxDuration when available', () {
      final startDate = DateTime(2024, 1, 15);
      final asset = Asset(
        id: 'a1',
        name: 'Projet Test',
        ticker: 'CROWD_TEST',
        type: AssetType.RealEstateCrowdfunding,
        expectedYield: 12.0,
        repaymentType: RepaymentType.MonthlyInterest,
        targetDuration: 12,
        maxDuration: 24,
        transactions: [
          Transaction(
            id: 't1',
            accountId: 'acc1',
            type: TransactionType.Buy,
            date: startDate,
            assetTicker: 'CROWD_TEST',
            assetName: 'Projet Test',
            quantity: 1000.0,
            price: 1.0,
            amount: -1000.0,
            fees: 0.0,
            notes: '',
            assetType: AssetType.RealEstateCrowdfunding,
          ),
        ],
      );

      final projections = service.generateProjections([asset]);
      final capital = projections.where((p) => p.type == TransactionType.CapitalRepayment).toList();
      expect(capital.length, 1);

      final expectedEnd = startDate.add(const Duration(days: 24 * 30));
      expect(capital.first.date.year, expectedEnd.year);
      expect(capital.first.date.month, expectedEnd.month);
    });

    test('generateProjections falls back to targetDuration when maxDuration is null', () {
      // Choisir une date de début suffisamment récente pour que la fin soit dans le futur
      final startDate = DateTime(2025, 7, 1);
      final asset = Asset(
        id: 'a2',
        name: 'Projet Target Seulement',
        ticker: 'CROWD_TARGET',
        type: AssetType.RealEstateCrowdfunding,
        expectedYield: 10.0,
        repaymentType: RepaymentType.InFine,
        targetDuration: 18,
        maxDuration: null,
        transactions: [
          Transaction(
            id: 't2',
            accountId: 'acc1',
            type: TransactionType.Buy,
            date: startDate,
            assetTicker: 'CROWD_TARGET',
            assetName: 'Projet Target Seulement',
            quantity: 500.0,
            price: 1.0,
            amount: -500.0,
            fees: 0.0,
            notes: '',
            assetType: AssetType.RealEstateCrowdfunding,
          ),
        ],
      );

      final projections = service.generateProjections([asset]);
      final capital = projections.where((p) => p.type == TransactionType.CapitalRepayment).toList();
      expect(capital.length, 1);

      final expectedEnd = startDate.add(const Duration(days: 18 * 30));
      expect(capital.first.date.year, expectedEnd.year);
      expect(capital.first.date.month, expectedEnd.month);
    });
  });
}
