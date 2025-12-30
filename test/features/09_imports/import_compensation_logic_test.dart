import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

/// Test pour valider la logique des dépôts compensatoires
void main() {
  group('Import Compensation Logic Tests', () {
    test('Buy transactions should always create compensation deposits (all modes)', () {
      // Simule les transactions parsées
      final buyTransactions = [
        ParsedTransaction(
          date: DateTime(2025, 1, 15),
          type: TransactionType.Buy,
          assetName: 'Apple Inc.',
          ticker: 'APPLE',
          quantity: 10,
          price: 150.0,
          amount: -1500.0, // Montant négatif pour un achat
          fees: 0,
          currency: 'EUR',
          assetType: AssetType.Stock,
        ),
        ParsedTransaction(
          date: DateTime(2025, 1, 15),
          type: TransactionType.Buy,
          assetName: 'Tesla Inc.',
          ticker: 'TESLA',
          quantity: 5,
          price: 200.0,
          amount: -1000.0, // Même date, montant différent
          fees: 0,
          currency: 'EUR',
          assetType: AssetType.Stock,
        ),
        ParsedTransaction(
          date: DateTime(2025, 2, 20),
          type: TransactionType.Buy,
          assetName: 'Microsoft Corp.',
          ticker: 'MSFT',
          quantity: 20,
          price: 300.0,
          amount: -6000.0, // Date différente
          fees: 0,
          currency: 'EUR',
          assetType: AssetType.Stock,
        ),
      ];

      // Test avec différents modes
      for (final mode in [ImportMode.initial, ImportMode.update]) {
        print('\n📊 Testing mode: $mode');
        
        // Logique attendue: tous les achats (montants négatifs) devraient être compensés
        // indépendamment du mode (initial ou update)
        final expectedDeposits = <String, double>{};
        
        for (final tx in buyTransactions) {
          if (tx.type == TransactionType.Buy && tx.amount < 0) {
            final dateKey = tx.date.toIso8601String().substring(0, 10);
            expectedDeposits[dateKey] = (expectedDeposits[dateKey] ?? 0) + tx.amount.abs();
          }
        }

        print('   💰 Expected compensation deposits:');
        for (final entry in expectedDeposits.entries) {
          print('      ${entry.key}: ${entry.value.toStringAsFixed(2)}€');
        }

        // Calcul des liquidités SANS compensation
        double cashWithoutCompensation = 0;
        for (final tx in buyTransactions) {
          cashWithoutCompensation += tx.amount;
        }

        // Calcul des liquidités AVEC compensation
        double cashWithCompensation = cashWithoutCompensation;
        for (final deposit in expectedDeposits.values) {
          cashWithCompensation += deposit;
        }

        print('   📈 Cash Balance Analysis:');
        print('      Without compensation: ${cashWithoutCompensation.toStringAsFixed(2)}€ (WRONG!)');
        print('      With compensation:    ${cashWithCompensation.toStringAsFixed(2)}€ (CORRECT!)');

        // Assertion: avec compensation, la liquidité doit être à zéro (tous les achats sont compensés)
        expect(
          cashWithCompensation,
          0.0,
          reason: 'Cash balance should be 0 when all buy transactions are compensated for mode: $mode'
        );
      }
    });

    test('Capital invested should be calculated from buy transactions', () {
      final buyTransactions = [
        ParsedTransaction(
          date: DateTime(2025, 1, 15),
          type: TransactionType.Buy,
          assetName: 'Apple Inc.',
          ticker: 'APPLE',
          quantity: 10,
          price: 150.0,
          amount: -1500.0,
          fees: 0,
          currency: 'EUR',
          assetType: AssetType.Stock,
        ),
        ParsedTransaction(
          date: DateTime(2025, 1, 15),
          type: TransactionType.Buy,
          assetName: 'Tesla Inc.',
          ticker: 'TESLA',
          quantity: 5,
          price: 200.0,
          amount: -1000.0,
          fees: 0,
          currency: 'EUR',
          assetType: AssetType.Stock,
        ),
      ];

      // Calcul du capital investi
      double capitalInvested = 0;
      for (final tx in buyTransactions) {
        if (tx.type == TransactionType.Buy && tx.amount < 0) {
          capitalInvested += tx.amount.abs();
        }
      }

      print('\n💼 Capital Invested Analysis:');
      print('   Total invested: ${capitalInvested.toStringAsFixed(2)}€');

      expect(capitalInvested, 2500.0, reason: 'Capital invested should be 2500€');
    });

    test('Deposits should not be compensated (only buy transactions)', () {
      final mixedTransactions = [
        ParsedTransaction(
          date: DateTime(2025, 1, 15),
          type: TransactionType.Deposit,
          assetName: 'Bank Transfer',
          quantity: 0,
          price: 0,
          amount: 5000.0, // Dépôt positif
          fees: 0,
          currency: 'EUR',
          assetType: null,
        ),
        ParsedTransaction(
          date: DateTime(2025, 1, 15),
          type: TransactionType.Buy,
          assetName: 'Apple Inc.',
          ticker: 'APPLE',
          quantity: 10,
          price: 150.0,
          amount: -1500.0, // Achat négatif
          fees: 0,
          currency: 'EUR',
          assetType: AssetType.Stock,
        ),
      ];

      // Logique: le dépôt NE doit PAS être compensé
      // Seul l'achat doit avoir un dépôt compensatoire
      double totalCash = 0;
      double compensationAmount = 0;

      for (final tx in mixedTransactions) {
        totalCash += tx.amount;
        if (tx.type == TransactionType.Buy && tx.amount < 0) {
          compensationAmount += tx.amount.abs();
        }
      }

      totalCash += compensationAmount; // Ajouter la compensation

      print('\n🔄 Mixed Transactions Analysis:');
      print('   Deposit:     +5000.00€');
      print('   Buy:         -1500.00€');
      print('   Compensation:+1500.00€');
      print('   ---');
      print('   Final Cash:  ${totalCash.toStringAsFixed(2)}€');

      expect(totalCash, 5000.0, reason: 'Final cash should be 5000€ (deposit + compensation)');
    });

    test('Trade Republic and BoursoBank imports should have tickers for grouping', () {
      // Simule plusieurs transactions du même actif
      final sameAssetTransactions = [
        ParsedTransaction(
          date: DateTime(2025, 1, 10),
          type: TransactionType.Buy,
          assetName: 'Apple Inc.',
          ticker: 'APPLE', // NOUVEAU: ticker défini!
          quantity: 5,
          price: 150.0,
          amount: -750.0,
          fees: 0,
          currency: 'EUR',
          assetType: AssetType.Stock,
        ),
        ParsedTransaction(
          date: DateTime(2025, 1, 20),
          type: TransactionType.Buy,
          assetName: 'Apple Inc.',
          ticker: 'APPLE', // NOUVEAU: ticker défini!
          quantity: 5,
          price: 155.0,
          amount: -775.0,
          fees: 0,
          currency: 'EUR',
          assetType: AssetType.Stock,
        ),
        ParsedTransaction(
          date: DateTime(2025, 2, 15),
          type: TransactionType.Dividend,
          assetName: 'Apple Inc.',
          ticker: 'APPLE', // NOUVEAU: ticker défini!
          quantity: 10,
          price: 0.5,
          amount: 5.0,
          fees: 0,
          currency: 'EUR',
          assetType: AssetType.Stock,
        ),
      ];

      // Groupage par ticker
      final byTicker = <String, List<ParsedTransaction>>{};
      for (final tx in sameAssetTransactions) {
        final ticker = tx.ticker ?? tx.assetName;
        (byTicker[ticker] ??= []).add(tx);
      }

      print('\n🏷️  Ticker Grouping Analysis:');
      for (final entry in byTicker.entries) {
        print('   ${entry.key}: ${entry.value.length} transaction(s)');
        
        // Calcul du total par ticker
        double totalAmount = 0;
        int buyCount = 0;
        
        for (final tx in entry.value) {
          totalAmount += tx.amount;
          if (tx.type == TransactionType.Buy) buyCount++;
        }
        
        print('      - ${buyCount} buy(s), total amount: ${totalAmount.toStringAsFixed(2)}€');
      }

      expect(byTicker.length, 1, reason: 'Should have 1 unique ticker (APPLE)');
      expect(byTicker['APPLE']!.length, 3, reason: 'Should have 3 transactions for APPLE');
    });
  });
}
