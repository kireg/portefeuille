import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

void main() {
  group('ImportDiffService', () {
    test('détecte doublon strict via clé d\'identité', () {
      final service = ImportDiffService();
      final date = DateTime(2024, 5, 20);

      final existing = [
        Transaction(
          id: 'e1',
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
        )
      ];

      final parsed = [
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
        )
      ];

      final diff = service.compute(parsed: parsed, existing: existing, mode: ImportMode.update);

      expect(diff.duplicates.length, 1);
      expect(diff.candidates.isEmpty, true);
    });

    test('détecte modifié via clé partielle si quantité/montant diffèrent', () {
      final service = ImportDiffService();
      final date = DateTime(2024, 5, 20);

      final existing = [
        Transaction(
          id: 'e2',
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
        )
      ];

      final parsed = [
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Asset XYZ',
          ticker: 'XYZ',
          quantity: 11.0, // diff > seuil
          price: 5.0,
          amount: 55.0, // diff > seuil
          fees: 0.0,
          currency: 'EUR',
        )
      ];

      final diff = service.compute(parsed: parsed, existing: existing, mode: ImportMode.update);

      expect(diff.duplicates.isEmpty, true);
      expect(diff.candidates.length, 1);
      expect(diff.candidates.first.isModified, true);
      expect(diff.candidates.first.existingMatch != null, true);
    });

    test('marque ISIN invalide', () {
      final service = ImportDiffService();
      final date = DateTime(2024, 5, 20);

      final existing = <Transaction>[];

      final parsed = [
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Asset DEF',
          isin: 'FR123', // invalide
          quantity: 1.0,
          price: 1.0,
          amount: 1.0,
          fees: 0.0,
          currency: 'EUR',
        )
      ];

      final diff = service.compute(parsed: parsed, existing: existing, mode: ImportMode.update);

      expect(diff.invalidIsins.length, 1);
      expect(diff.candidates.length, 1);
    });

    test('accepte ISIN valide', () {
      final service = ImportDiffService();
      final date = DateTime(2024, 5, 20);

      final parsed = [
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Apple Inc',
          isin: 'US0378331005', // ISIN valide Apple
          quantity: 10.0,
          price: 150.0,
          amount: 1500.0,
          fees: 0.0,
          currency: 'USD',
        )
      ];

      final diff = service.compute(parsed: parsed, existing: [], mode: ImportMode.initial);

      expect(diff.invalidIsins, isEmpty);
      expect(diff.candidates.length, 1);
    });

    test('mode Initial ne cherche pas de match à modifier', () {
      final service = ImportDiffService();
      final date = DateTime(2024, 5, 20);

      final existing = [
        Transaction(
          id: 'e1',
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
        )
      ];

      // Même date/ticker/type mais quantité différente
      final parsed = [
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Asset XYZ',
          ticker: 'XYZ',
          quantity: 15.0, // différent
          price: 5.0,
          amount: 75.0,
          fees: 0.0,
          currency: 'EUR',
        )
      ];

      // Mode initial: pas de recherche de match
      final diff = service.compute(parsed: parsed, existing: existing, mode: ImportMode.initial);

      // Pas de doublon strict (quantité différente)
      expect(diff.duplicates, isEmpty);
      // Candidat ajouté comme nouveau (pas de isModified en mode initial)
      expect(diff.candidates.length, 1);
      expect(diff.candidates.first.isModified, false);
      expect(diff.candidates.first.existingMatch, isNull);
    });

    test('ignore les transactions avec quantité/montant identiques sous le seuil', () {
      final service = ImportDiffService();
      final date = DateTime(2024, 5, 20);

      final existing = [
        Transaction(
          id: 'e1',
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
        )
      ];

      // Légère différence sous le seuil
      final parsed = [
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Asset ABC',
          ticker: 'ABC',
          quantity: 10.00005, // diff < 0.0001
          price: 5.0,
          amount: 50.005, // diff < 0.01
          fees: 0.0,
          currency: 'EUR',
        )
      ];

      final diff = service.compute(parsed: parsed, existing: existing, mode: ImportMode.update);

      // Considéré comme doublon car différence sous le seuil
      expect(diff.duplicates.length, 1);
      expect(diff.candidates, isEmpty);
    });

    test('gère les transactions sans ticker via ISIN', () {
      final service = ImportDiffService();
      final date = DateTime(2024, 5, 20);

      final existing = [
        Transaction(
          id: 'e1',
          accountId: 'acc',
          type: TransactionType.Buy,
          date: date,
          assetTicker: 'FR0000120578',
          assetName: 'Sanofi',
          quantity: 10.0,
          price: 90.0,
          amount: 900.0,
          fees: 0.0,
          notes: '',
          priceCurrency: 'EUR',
        )
      ];

      final parsed = [
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Sanofi',
          isin: 'FR0000120578',
          quantity: 10.0,
          price: 90.0,
          amount: 900.0,
          fees: 0.0,
          currency: 'EUR',
        )
      ];

      final diff = service.compute(parsed: parsed, existing: existing, mode: ImportMode.update);

      expect(diff.duplicates.length, 1);
      expect(diff.candidates, isEmpty);
    });

    test('gère les transactions sans ticker ni ISIN via assetName', () {
      final service = ImportDiffService();
      final date = DateTime(2024, 5, 20);

      final existing = [
        Transaction(
          id: 'e1',
          accountId: 'acc',
          type: TransactionType.Deposit,
          date: date,
          assetTicker: null,
          assetName: 'Cash EUR',
          quantity: 0,
          price: 1,
          amount: 500.0,
          fees: 0.0,
          notes: '',
          priceCurrency: 'EUR',
        )
      ];

      final parsed = [
        ParsedTransaction(
          date: date,
          type: TransactionType.Deposit,
          assetName: 'Cash EUR',
          quantity: 0,
          price: 1,
          amount: 500.0,
          fees: 0.0,
          currency: 'EUR',
        )
      ];

      final diff = service.compute(parsed: parsed, existing: existing, mode: ImportMode.update);

      expect(diff.duplicates.length, 1);
      expect(diff.candidates, isEmpty);
    });
  });
}
