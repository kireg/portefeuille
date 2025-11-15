// lib/features/00_app/providers/portfolio_sync_logic.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

// --- MODIFIÉ : Classe de résultat plus détaillée ---
class SyncResult {
  final int fmpUpdates;
  final int yahooUpdates;
  final int cacheUpdates;
  final List<String> failedTickers;

  SyncResult({
    this.fmpUpdates = 0,
    this.yahooUpdates = 0,
    this.cacheUpdates = 0,
    this.failedTickers = const [],
  });
  int get updatedCount => fmpUpdates + yahooUpdates;
  int get failedCount => failedTickers.length;
  /// Construit un message de résumé détaillé pour l'utilisateur
  String getSummaryMessage() {
    if (updatedCount == 0 && failedCount == 0 && cacheUpdates == 0) {
      return "Synchro terminée : Aucun prix à mettre à jour.";
    }
    if (updatedCount == 0 && failedCount == 0 && cacheUpdates > 0) {
      return "Synchro terminée : Prix déjà à jour (Cache).";
    }

    List<String> parts = [];
    if (fmpUpdates > 0) parts.add("$fmpUpdates via FMP");
    if (yahooUpdates > 0) parts.add("$yahooUpdates via Yahoo");

    String summary = "Synchro : ${parts.join(', ')}.";
    if (failedCount > 0) {
      summary +=
      "\nÉchecs : ${failedCount} (${failedTickers.take(3).join(', ')}${failedCount > 3 ? ', ...' : ''})";
    }
    return summary;
  }
}
// --- FIN MODIFICATION ---

class PortfolioSyncLogic {
  final PortfolioRepository repository;
  final ApiService apiService;
  SettingsProvider settingsProvider;

  PortfolioSyncLogic({
    required this.repository,
    required this.apiService,
    required this.settingsProvider,
  });

  /// Force la synchronisation des prix en vidant d'abord le cache.
  Future<SyncResult> forceSynchroniserLesPrix(Portfolio activePortfolio) async {
    apiService.clearCache();
    return await synchroniserLesPrix(activePortfolio);
  }

  /// Synchronise les prix en utilisant la logique de fallback de l'ApiService
  Future<SyncResult> synchroniserLesPrix(Portfolio activePortfolio) async {
    if (!settingsProvider.isOnlineMode) {
      return SyncResult();
    }

    Set<String> tickers = {};

    try {
      // 1. Aplatir tous les actifs et extraire les tickers uniques
      List<Asset> allAssets = [];
      for (var inst in activePortfolio.institutions) {
        for (var acc in inst.accounts) {
          allAssets.addAll(acc.assets);
        }
      }
      tickers =
          allAssets.map((a) => a.ticker).where((t) => t.isNotEmpty).toSet();
      if (tickers.isEmpty) {
        return SyncResult();
      }

      // 2. Appeler l'API pour tous les tickers en parallèle
      final List<Future<PriceResult>> futures =
      tickers.map((ticker) => apiService.getPrice(ticker)).toList();
      final results = await Future.wait(futures);

      // 3. Traiter les résultats
      int fmpUpdates = 0;
      int yahooUpdates = 0;
      int cacheUpdates = 0;
      List<String> failedTickers = [];
      List<Future<void>> saveFutures = [];

      for (final result in results) {
        final newPrice = result.price;
        final newCurrency = result.currency;
        final source = result.source;

        if (newPrice != null) {
          final metadata = repository.getOrCreateAssetMetadata(result.ticker);

          // --- CORRECTION DE L'ERREUR ---
          // On vérifie si le prix OU la devise a changé
          if (metadata.currentPrice != newPrice ||
              metadata.priceCurrency != newCurrency) {
            // On utilise la nouvelle signature
            metadata.updatePrice(newPrice, newCurrency);
            // --- FIN CORRECTION ---

            saveFutures.add(repository.saveAssetMetadata(metadata));

            if (source == ApiSource.Fmp) fmpUpdates++;
            if (source == ApiSource.Yahoo) yahooUpdates++;
          } else if (source == ApiSource.Cache) {
            cacheUpdates++;
          }
        } else {
          // source == ApiSource.None
          failedTickers.add(result.ticker);
        }
      }

      // 4. Sauvegarder les métadonnées mises à jour en parallèle
      if (saveFutures.isNotEmpty) {
        await Future.wait(saveFutures);
      }

      return SyncResult(
        fmpUpdates: fmpUpdates,
        yahooUpdates: yahooUpdates,
        cacheUpdates: cacheUpdates,
        failedTickers: failedTickers,
      );
    } catch (e) {
      debugPrint("⚠️ Erreur lors de la synchronisation des prix : $e");
      return SyncResult(
        failedTickers: tickers.toList(),
      );
    }
  }
}