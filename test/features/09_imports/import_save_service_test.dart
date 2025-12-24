import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/services/import_save_service.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

class FakeTransactionProvider extends TransactionProvider {
  FakeTransactionProvider() : super(transactionService: _DummyService(), portfolioProvider: _DummyPortfolioProvider());

  final List<Transaction> added = [];
  final List<Transaction> updated = [];

  @override
  Future<void> addTransactions(List<Transaction> transactions) async {
    added.addAll(transactions);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    updated.add(transaction);
  }
}

// Dummies to satisfy base class; not used in tests.
class _DummyService {}
class _DummyPortfolioProvider {}

void main() {
  group('ImportSaveService', () {
    test('ajoute nouveaux et met à jour modifiés', () async {
      final provider = FakeTransactionProvider();
      final date = DateTime(2024, 5, 20);

      final existing = [
        Transaction(
          id: 't_mod',
          accountId: 'acc',
          type: TransactionType.Buy,
          date: date,
          assetTicker: 'XYZ',
          assetName: 'Asset XYZ',
          quantity: 10.0,
          price: 5.0,
          amount: 50.0,
          fees: 0.0,
          notes: '',
          priceCurrency: 'EUR',
        ),
      ];

      final parsed = [
        // modifié
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Asset XYZ',
          ticker: 'XYZ',
          quantity: 11.0,
          price: 5.5,
          amount: 60.5,
          fees: 0.0,
          currency: 'EUR',
        ),
        // nouveau
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Asset NEW',
          ticker: 'NEW',
          quantity: 2.0,
          price: 10.0,
          amount: 20.0,
          fees: 0.0,
          currency: 'EUR',
        ),
      ];

      final diff = ImportDiffService().compute(parsed: parsed, existing: existing, mode: ImportMode.update);
      diff.candidates.forEach((c) => c.selected = true);

      final count = await ImportSaveService.saveSelected(
        provider: provider,
        candidates: diff.candidates,
        accountId: 'acc',
        mode: ImportMode.update,
        sourceId: 'trade_republic',
      );

      expect(count, 2);
      expect(provider.added.length, 1);
      expect(provider.updated.length, 1);
      expect(provider.updated.first.id, 't_mod');
    });
  });
}
