import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

void main() {
  group('Asset Future Transactions Logic', () {
    test('Should exclude future transactions from quantity calculation', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 10));
      final pastDate = now.subtract(const Duration(days: 10));

      final asset = Asset(
        id: '1',
        name: 'Test Asset',
        ticker: 'TST',
        type: AssetType.Stock,
        transactions: [
          Transaction(
            id: 't1',
            accountId: 'a1',
            date: pastDate,
            type: TransactionType.Buy,
            quantity: 10.0,
            price: 100.0,
            fees: 0.0,
            amount: -1000.0,
          ),
          Transaction(
            id: 't2',
            accountId: 'a1',
            date: futureDate,
            type: TransactionType.Buy,
            quantity: 5.0,
            price: 100.0,
            fees: 0.0,
            amount: -500.0,
          ),
        ],
      );

      // Should only count the past transaction (10.0)
      expect(asset.quantity, 10.0);
    });

    test('Should exclude future transactions from totalInvestedCapital', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 10));
      final pastDate = now.subtract(const Duration(days: 10));

      final asset = Asset(
        id: '1',
        name: 'Test Asset',
        ticker: 'TST',
        type: AssetType.Stock,
        transactions: [
          Transaction(
            id: 't1',
            accountId: 'a1',
            date: pastDate,
            type: TransactionType.Buy,
            quantity: 10.0,
            price: 100.0,
            fees: 5.0,
            amount: -1000.0, // Invested: 1000 + 5 = 1005
          ),
          Transaction(
            id: 't2',
            accountId: 'a1',
            date: futureDate,
            type: TransactionType.Buy,
            quantity: 5.0,
            price: 100.0,
            fees: 5.0,
            amount: -500.0,
          ),
        ],
      );

      // Should only count the past transaction
      expect(asset.totalInvestedCapital, 1005.0);
    });

    test('Should exclude future transactions from averagePrice (PRU)', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 10));
      final pastDate = now.subtract(const Duration(days: 10));

      final asset = Asset(
        id: '1',
        name: 'Test Asset',
        ticker: 'TST',
        type: AssetType.Stock,
        transactions: [
          Transaction(
            id: 't1',
            accountId: 'a1',
            date: pastDate,
            type: TransactionType.Buy,
            quantity: 10.0,
            price: 100.0,
            fees: 0.0,
            amount: -1000.0,
          ),
          Transaction(
            id: 't2',
            accountId: 'a1',
            date: futureDate,
            type: TransactionType.Buy,
            quantity: 10.0,
            price: 200.0, // Would change PRU if included
            fees: 0.0,
            amount: -2000.0,
          ),
        ],
      );

      // PRU should be 100.0 (from past transaction only)
      expect(asset.averagePrice, 100.0);
    });

    test('Should exclude future transactions from totalValue (Crowdfunding)', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 10));
      final pastDate = now.subtract(const Duration(days: 365)); // 1 year ago

      final asset = Asset(
        id: '1',
        name: 'Test Project',
        ticker: 'PRJ',
        type: AssetType.RealEstateCrowdfunding,
        expectedYield: 10.0, // 10%
        transactions: [
          Transaction(
            id: 't1',
            accountId: 'a1',
            date: pastDate,
            type: TransactionType.Buy,
            quantity: 1.0,
            price: 1000.0,
            fees: 0.0,
            amount: -1000.0,
          ),
          Transaction(
            id: 't2',
            accountId: 'a1',
            date: futureDate,
            type: TransactionType.Buy,
            quantity: 1.0,
            price: 1000.0,
            fees: 0.0,
            amount: -1000.0,
          ),
        ],
      );

      // Past transaction: 1000 invested + 10% interest for 1 year (approx 100) = 1100
      // Future transaction: Should be ignored.
      
      expect(asset.totalValue, closeTo(1100.0, 5.0));
    });
  });
}