// lib/features/00_app/services/demo_data_service.dart

import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/features/00_app/services/demo_data/demo_metadata_data.dart';
import 'package:portefeuille/features/00_app/services/demo_data/demo_portfolio_data.dart';
import 'package:portefeuille/features/00_app/services/demo_data/demo_transactions_data.dart';
import 'package:uuid/uuid.dart';

class DemoDataService {
  final PortfolioRepository _repository;
  final Uuid _uuid;

  DemoDataService({
    required PortfolioRepository repository,
    Uuid? uuid,
  })  : _repository = repository,
        _uuid = uuid ?? const Uuid();

  /// Crée et sauvegarde un portefeuille de démo.
  /// Retourne le portfolio créé.
  Future<Portfolio> createDemoPortfolio() async {
    final data = _generateDemoData();

    await _repository.savePortfolio(data.portfolio);

    await Future.wait([
      ...data.transactions.map(_repository.saveTransaction),
      ...data.metadata.map(_repository.saveAssetMetadata),
    ]);

    return data.portfolio;
  }

  _DemoData _generateDemoData() {
    final demoPortfolioId = _uuid.v4();
    final ctoAccountId = _uuid.v4();
    final peaAccountId = _uuid.v4();
    final assuranceVieAccountId = _uuid.v4();
    final cryptoAccountId = _uuid.v4();

    final demoPortfolio = getDemoPortfolio(
      _uuid,
      demoPortfolioId,
      peaAccountId,
      ctoAccountId,
      assuranceVieAccountId,
      cryptoAccountId,
    );

    final demoTransactions = getDemoTransactions(
      _uuid,
      peaAccountId,
      ctoAccountId,
      assuranceVieAccountId,
      cryptoAccountId,
    );

    final demoMetadata = getDemoMetadata();

    return _DemoData(
      portfolio: demoPortfolio,
      transactions: demoTransactions,
      metadata: demoMetadata,
    );
  }
}

class _DemoData {
  final Portfolio portfolio;
  final List<Transaction> transactions;
  final List<AssetMetadata> metadata;

  const _DemoData({
    required this.portfolio,
    required this.transactions,
    required this.metadata,
  });
}