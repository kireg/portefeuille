import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

void main() {
  group('Wizard save logic using ImportCandidate', () {
    test('sépare nouveaux et modifiés et permet la mise à jour/addition', () async {
      final date = DateTime(2024, 5, 20);

      // existing: un doublon strict, un match à modifier
      final existing = [
        Transaction(
          id: 't_dup',
          accountId: 'acc',
          type: TransactionType.Buy,
          date: date,
          assetTicker: 'ABC',
          assetName: 'Asset ABC',
          quantity: 10.0,
          price: 5.0,
          amount: 50.0,
          fees: 0.0,
          notes: '',
          priceCurrency: 'EUR',
        ),
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
        // doublon strict
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Asset ABC',
          ticker: 'ABC',
          quantity: 10.0,
          price: 5.0,
          amount: 50.0,
          fees: 0.0,
          currency: 'EUR',
        ),
        // modifié (quantité/montant)
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Asset XYZ',
          ticker: 'XYZ',
          quantity: 11.0,
          price: 5.0,
          amount: 55.0,
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

      final diff = ImportDiffService().compute(
        parsed: parsed,
        existing: existing,
        mode: ImportMode.update,
      );

      // Check classification
      expect(diff.duplicates.length, 1);
      expect(diff.invalidIsins.isEmpty, true);
      expect(diff.candidates.length, 2);
      final modified = diff.candidates.firstWhere((c) => c.isModified);
      final added = diff.candidates.firstWhere((c) => !c.isModified);
      expect(modified.existingMatch!.id, 't_mod');
      expect(added.existingMatch == null, true);

      // Simulate selection toggles
      modified.selected = true;
      added.selected = true;
      // No-op: duplicates are not candidates

      // We don't call providers here; this test focuses on classification consistency.
      // The wizard will perform add/update accordingly with selected candidates.
    });
  });
}
