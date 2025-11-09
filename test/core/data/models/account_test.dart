// test/core/data/models/account_test.dart
// Test unitaire pour valider les getters Account

import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

void main() {
  group('Account - Calcul dynamique du cashBalance', () {
    test('Dépôt simple augmente le solde', () {
      final account = Account(
        id: 'test-account-1',
        name: 'Compte Test',
        type: AccountType.cto,
        transactions: [
          Transaction(
            id: 'tx-1',
            accountId: 'test-account-1',
            type: TransactionType.Deposit,
            date: DateTime(2024, 1, 1),
            amount: 1000.0,
          ),
        ],
      );

      expect(account.cashBalance, 1000.0);
    });

    test('Achat d\'actif réduit le solde', () {
      final account = Account(
        id: 'test-account-1',
        name: 'Compte Test',
        type: AccountType.cto,
        transactions: [
          Transaction(
            id: 'tx-1',
            accountId: 'test-account-1',
            type: TransactionType.Deposit,
            date: DateTime(2024, 1, 1),
            amount: 1000.0,
          ),
          Transaction(
            id: 'tx-2',
            accountId: 'test-account-1',
            type: TransactionType.Buy,
            date: DateTime(2024, 1, 2),
            assetTicker: 'AAPL',
            assetName: 'Apple Inc.',
            assetType: AssetType.Stock,
            quantity: 5,
            price: 150.0,
            amount: -750.0,
            fees: 10.0,
          ),
        ],
      );

      // Solde = 1000 (dépôt) - 750 (achat) - 10 (frais) = 240
      expect(account.cashBalance, 240.0);
    });

    test('Vente d\'actif augmente le solde', () {
      final account = Account(
        id: 'test-account-1',
        name: 'Compte Test',
        type: AccountType.cto,
        transactions: [
          Transaction(
            id: 'tx-1',
            accountId: 'test-account-1',
            type: TransactionType.Deposit,
            date: DateTime(2024, 1, 1),
            amount: 1000.0,
          ),
          Transaction(
            id: 'tx-2',
            accountId: 'test-account-1',
            type: TransactionType.Buy,
            date: DateTime(2024, 1, 2),
            assetTicker: 'AAPL',
            assetName: 'Apple Inc.',
            assetType: AssetType.Stock,
            quantity: 5,
            price: 150.0,
            amount: -750.0,
            fees: 10.0,
          ),
          Transaction(
            id: 'tx-3',
            accountId: 'test-account-1',
            type: TransactionType.Sell,
            date: DateTime(2024, 1, 3),
            assetTicker: 'AAPL',
            assetName: 'Apple Inc.',
            assetType: AssetType.Stock,
            quantity: 2,
            price: 160.0,
            amount: 320.0,
            fees: 5.0,
          ),
        ],
      );

      // Solde = 1000 - 750 - 10 + 320 - 5 = 555
      expect(account.cashBalance, 555.0);
    });
  });

  group('Account - Calcul dynamique des actifs', () {
    test('Un achat crée un actif', () {
      final account = Account(
        id: 'test-account-1',
        name: 'Compte Test',
        type: AccountType.cto,
        transactions: [
          Transaction(
            id: 'tx-1',
            accountId: 'test-account-1',
            type: TransactionType.Deposit,
            date: DateTime(2024, 1, 1),
            amount: 1000.0,
          ),
          Transaction(
            id: 'tx-2',
            accountId: 'test-account-1',
            type: TransactionType.Buy,
            date: DateTime(2024, 1, 2),
            assetTicker: 'AAPL',
            assetName: 'Apple Inc.',
            assetType: AssetType.Stock,
            quantity: 5,
            price: 150.0,
            amount: -750.0,
            fees: 10.0,
          ),
        ],
      );

      final assets = account.assets;
      expect(assets.length, 1);
      expect(assets.first.ticker, 'AAPL');
      expect(assets.first.quantity, 5.0);
      // PRU = (5 * 150 + 10) / 5 = 760 / 5 = 152
      expect(assets.first.averagePrice, 152.0);
    });

    test('Achats multiples mettent à jour le PRU', () {
      final account = Account(
        id: 'test-account-1',
        name: 'Compte Test',
        type: AccountType.cto,
        transactions: [
          Transaction(
            id: 'tx-1',
            accountId: 'test-account-1',
            type: TransactionType.Buy,
            date: DateTime(2024, 1, 1),
            assetTicker: 'AAPL',
            assetName: 'Apple Inc.',
            assetType: AssetType.Stock,
            quantity: 5,
            price: 100.0,
            amount: -500.0,
            fees: 5.0,
          ),
          Transaction(
            id: 'tx-2',
            accountId: 'test-account-1',
            type: TransactionType.Buy,
            date: DateTime(2024, 1, 2),
            assetTicker: 'AAPL',
            assetName: 'Apple Inc.',
            assetType: AssetType.Stock,
            quantity: 5,
            price: 120.0,
            amount: -600.0,
            fees: 5.0,
          ),
        ],
      );

      final assets = account.assets;
      expect(assets.length, 1);
      expect(assets.first.quantity, 10.0);
      // PRU = ((5*100 + 5) + (5*120 + 5)) / 10 = (505 + 605) / 10 = 111
      expect(assets.first.averagePrice, 111.0);
    });

    test('Vente complète supprime l\'actif', () {
      final account = Account(
        id: 'test-account-1',
        name: 'Compte Test',
        type: AccountType.cto,
        transactions: [
          Transaction(
            id: 'tx-1',
            accountId: 'test-account-1',
            type: TransactionType.Buy,
            date: DateTime(2024, 1, 1),
            assetTicker: 'AAPL',
            assetName: 'Apple Inc.',
            assetType: AssetType.Stock,
            quantity: 5,
            price: 100.0,
            amount: -500.0,
            fees: 0.0,
          ),
          Transaction(
            id: 'tx-2',
            accountId: 'test-account-1',
            type: TransactionType.Sell,
            date: DateTime(2024, 1, 2),
            assetTicker: 'AAPL',
            assetName: 'Apple Inc.',
            assetType: AssetType.Stock,
            quantity: 5,
            price: 120.0,
            amount: 600.0,
            fees: 0.0,
          ),
        ],
      );

      final assets = account.assets;
      expect(assets.length, 0); // L'actif ne doit plus apparaître
    });

    test('Vente partielle réduit la quantité', () {
      final account = Account(
        id: 'test-account-1',
        name: 'Compte Test',
        type: AccountType.cto,
        transactions: [
          Transaction(
            id: 'tx-1',
            accountId: 'test-account-1',
            type: TransactionType.Buy,
            date: DateTime(2024, 1, 1),
            assetTicker: 'AAPL',
            assetName: 'Apple Inc.',
            assetType: AssetType.Stock,
            quantity: 10,
            price: 100.0,
            amount: -1000.0,
            fees: 0.0,
          ),
          Transaction(
            id: 'tx-2',
            accountId: 'test-account-1',
            type: TransactionType.Sell,
            date: DateTime(2024, 1, 2),
            assetTicker: 'AAPL',
            assetName: 'Apple Inc.',
            assetType: AssetType.Stock,
            quantity: 3,
            price: 120.0,
            amount: 360.0,
            fees: 0.0,
          ),
        ],
      );

      final assets = account.assets;
      expect(assets.length, 1);
      expect(assets.first.quantity, 7.0); // 10 - 3
      expect(assets.first.averagePrice, 100.0); // PRU inchangé
    });
  });
}
