// lib/features/00_app/services/hydration_service.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';

class HydrationService {
  final PortfolioRepository _repository;
  final ApiService _apiService;

  HydrationService({
    required PortfolioRepository repository,
    required ApiService apiService,
  })  : _repository = repository,
        _apiService = apiService;

  /// Hydrate tous les portfolios avec prix et taux de change.
  /// Chaque actif est hydraté vers la devise de son compte.
  Future<List<Portfolio>> hydrateAll() async {
    debugPrint("🔄 [HydrationService] Début de l'hydratation...");

    final portfolios = _repository.getAllPortfolios();
    final allMetadata = _repository.getAllAssetMetadata();

    final hydrationTasks = <Future<void>>[];

    for (final portfolio in portfolios) {
      for (final inst in portfolio.institutions) {
        for (final acc in inst.accounts) {
          for (final asset in acc.assets) {
            hydrationTasks.add(_hydrateAsset(
              asset: asset,
              accountCurrency: acc.activeCurrency,
              metadata: allMetadata[asset.ticker],
            ));
          }
        }
      }
    }

    try {
      await Future.wait(hydrationTasks);
      debugPrint("✅ [HydrationService] Hydratation terminée.");
    } catch (e) {
      debugPrint("❌ [HydrationService] Erreur durant l'hydratation: $e");
      rethrow;
    }

    return portfolios;
  }

  Future<void> _hydrateAsset({
    required Asset asset,
    required String accountCurrency,
    required AssetMetadata? metadata,
  }) async {
    if (metadata == null) {
      asset.currentPrice = 0.0;
      asset.priceCurrency = accountCurrency;
      asset.currentExchangeRate = 1.0;
      asset.estimatedAnnualYield = 0.0;
      return;
    }

    asset.currentPrice = metadata.currentPrice;
    asset.priceCurrency = metadata.activeCurrency;
    asset.estimatedAnnualYield = metadata.estimatedAnnualYield;

    asset.currentExchangeRate = await _apiService.getExchangeRate(
      metadata.activeCurrency,
      accountCurrency,
    );
  }
}