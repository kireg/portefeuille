import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/features/00_app/services/history_reconstruction_service.dart';

import 'package:portefeuille/core/data/models/account_type.dart';

void main() {
  group('HistoryReconstructionService', () {
    late HistoryReconstructionService service;

    setUp(() {
      service = HistoryReconstructionService();
    });

    test('reconstructHistory should generate points correctly', () {
      final now = DateTime.now();
      final date1 = now.subtract(const Duration(days: 10));
      final date2 = now.subtract(const Duration(days: 5));

      final tx1 = Transaction(
        id: '1',
        accountId: 'acc1',
        type: TransactionType.Buy,
        date: date1,
        assetTicker: 'AAPL',
        assetName: 'Apple',
        quantity: 10,
        price: 100,
        amount: 1000,
        fees: 0,
      );

      final tx2 = Transaction(
        id: '2',
        accountId: 'acc1',
        type: TransactionType.Buy,
        date: date2,
        assetTicker: 'AAPL',
        assetName: 'Apple',
        quantity: 5,
        price: 110, // Price increases
        amount: 550,
        fees: 0,
      );

      final account = Account(id: 'acc1', name: 'Acc 1', type: AccountType.cto, transactions: [tx1, tx2]);
      final institution = Institution(id: 'inst1', name: 'Inst 1', accounts: [account]);
      final portfolio = Portfolio(id: 'p1', name: 'Portfolio 1', institutions: [institution]);

      final history = service.reconstructHistory(portfolio);

      expect(history, isNotEmpty);
      // Should have points from date1 to now (11 days)
      expect(history.length, greaterThanOrEqualTo(11));

      // Check value at date1 (10 * 100 = 1000)
      final point1 = history.firstWhere((p) => p.date.year == date1.year && p.date.month == date1.month && p.date.day == date1.day);
      expect(point1.value, 1000.0);

      // Check value at date2 (15 * 110 = 1650)
      final point2 = history.firstWhere((p) => p.date.year == date2.year && p.date.month == date2.month && p.date.day == date2.day);
      expect(point2.value, 1650.0);
      
      // Check value between date1 and date2 (should be 10 * 100 = 1000)
      final dateBetween = date1.add(const Duration(days: 2));
      final pointBetween = history.firstWhere((p) => p.date.year == dateBetween.year && p.date.month == dateBetween.month && p.date.day == dateBetween.day);
      expect(pointBetween.value, 1000.0);
    });
  });
}
