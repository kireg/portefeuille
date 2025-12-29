import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/services/transaction_service.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/core/data/abstractions/i_settings.dart';
import '../../test_harness.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/services/import_save_service.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

class FakeTransactionProvider extends TransactionProvider {
  FakeTransactionProvider()
      : super(
          transactionService: _DummyTransactionService(),
          portfolioProvider: _DummyPortfolioProvider(),
        );

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

class _DummyTransactionService extends TransactionService {
  _DummyTransactionService() : super(repository: PortfolioRepository());
}

class _DummySettings implements ISettings {
  @override
  String? get fmpApiKey => null;
  @override
  bool get hasFmpApiKey => false;
  @override
  String get baseCurrency => 'EUR';
  @override
  int get appColorValue => 0xFF000000;
  @override
  List<String> get serviceOrder => const ['FMP', 'Yahoo'];
}

class _DummyPortfolioProvider extends PortfolioProvider {
  _DummyPortfolioProvider()
      : super(
          repository: PortfolioRepository(),
          apiService: ApiService(settings: _DummySettings()),
        );
}

void main() {
  late Directory hiveDir;
  setUpAll(() async {
    hiveDir = await initTestHive();
  });

  tearDownAll(() async {
    await tearDownTestHive(hiveDir);
  });
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
        portfolioProvider: _DummyPortfolioProvider(),
        candidates: diff.candidates,
        accountId: 'acc',
        mode: ImportMode.update,
        sourceId: 'trade_republic',
      );

      expect(count, 2);
      // 1 nouveau + 1 dépôt compensatoire (le modifié ne crée pas de dépôt)
      expect(provider.added.length, 2);
      expect(provider.updated.length, 1);
      expect(provider.updated.first.id, 't_mod');
    });

    test('génère des IDs courts même avec un nom d’actif très long', () async {
      final provider = FakeTransactionProvider();
      final date = DateTime(2024, 5, 20);

      final longName = 'A' * 400; // > 255 caractères

      final parsed = [
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: longName,
          ticker: 'LONG',
          quantity: 1.0,
          price: 10.0,
          amount: 10.0,
          fees: 0.0,
          currency: 'EUR',
        ),
      ];

      final diff =
          ImportDiffService().compute(parsed: parsed, existing: [], mode: ImportMode.initial);
      diff.candidates.forEach((c) => c.selected = true);

      final count = await ImportSaveService.saveSelected(
        provider: provider,
        portfolioProvider: _DummyPortfolioProvider(),
        candidates: diff.candidates,
        accountId: 'acc',
        mode: ImportMode.initial,
        sourceId: 'trade_republic',
      );

      expect(count, 1);
      // 1 transaction + 1 dépôt compensatoire pour le Buy
      expect(provider.added, hasLength(2));
      // Vérifier que la transaction principale a un ID court
      final mainTx = provider.added.firstWhere((t) => t.type == TransactionType.Buy);
      expect(mainTx.id.length, lessThan(255));
    });

    test('crée un dépôt compensatoire pour les imports crowdfunding', () async {
      final provider = FakeTransactionProvider();
      final date = DateTime(2024, 6, 15);

      final parsed = [
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Projet Alpha',
          ticker: 'Projet Alpha',
          quantity: 1000.0,
          price: 1.0,
          amount: -1000.0, // Négatif selon la convention
          fees: 0.0,
          currency: 'EUR',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
        ParsedTransaction(
          date: date,
          type: TransactionType.Buy,
          assetName: 'Projet Beta',
          ticker: 'Projet Beta',
          quantity: 500.0,
          price: 1.0,
          amount: -500.0,
          fees: 0.0,
          currency: 'EUR',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
      ];

      final diff = ImportDiffService().compute(parsed: parsed, existing: [], mode: ImportMode.initial);
      diff.candidates.forEach((c) => c.selected = true);

      final count = await ImportSaveService.saveSelected(
        provider: provider,
        portfolioProvider: _DummyPortfolioProvider(),
        candidates: diff.candidates,
        accountId: 'acc_cf',
        mode: ImportMode.initial,
        sourceId: 'la_premiere_brique',
      );

      expect(count, 2);
      
      // 2 achats + 1 dépôt compensatoire (regroupé par date)
      expect(provider.added.length, 3);
      
      // Vérifier les achats
      final buys = provider.added.where((t) => t.type == TransactionType.Buy).toList();
      expect(buys.length, 2);
      expect(buys.every((t) => t.amount < 0), true, reason: 'Les achats doivent avoir un montant négatif');
      
      // Vérifier le dépôt compensatoire
      final deposits = provider.added.where((t) => t.type == TransactionType.Deposit).toList();
      expect(deposits.length, 1);
      expect(deposits.first.amount, 1500.0); // 1000 + 500
      expect(deposits.first.notes, contains('Apport auto'));
      expect(deposits.first.notes, contains('Crowdfunding'));
    });

    test('crée plusieurs dépôts compensatoires pour différentes dates crowdfunding', () async {
      final provider = FakeTransactionProvider();
      final date1 = DateTime(2024, 6, 15);
      final date2 = DateTime(2024, 7, 20);

      final parsed = [
        ParsedTransaction(
          date: date1,
          type: TransactionType.Buy,
          assetName: 'Projet Alpha',
          ticker: 'Projet Alpha',
          quantity: 1000.0,
          price: 1.0,
          amount: -1000.0,
          fees: 0.0,
          currency: 'EUR',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
        ParsedTransaction(
          date: date2,
          type: TransactionType.Buy,
          assetName: 'Projet Beta',
          ticker: 'Projet Beta',
          quantity: 500.0,
          price: 1.0,
          amount: -500.0,
          fees: 0.0,
          currency: 'EUR',
          assetType: AssetType.RealEstateCrowdfunding,
        ),
      ];

      final diff = ImportDiffService().compute(parsed: parsed, existing: [], mode: ImportMode.initial);
      diff.candidates.forEach((c) => c.selected = true);

      final count = await ImportSaveService.saveSelected(
        provider: provider,
        portfolioProvider: _DummyPortfolioProvider(),
        candidates: diff.candidates,
        accountId: 'acc_cf',
        mode: ImportMode.initial,
        sourceId: 'la_premiere_brique',
      );

      expect(count, 2);
      
      // 2 achats + 2 dépôts compensatoires (un par date)
      expect(provider.added.length, 4);
      
      final deposits = provider.added.where((t) => t.type == TransactionType.Deposit).toList();
      expect(deposits.length, 2);
      expect(deposits.map((d) => d.amount).toSet(), {1000.0, 500.0});
    });
  });
}
