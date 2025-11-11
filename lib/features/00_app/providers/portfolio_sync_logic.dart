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
      // CORRIGÉ : Constructeur par défaut
      return SyncResult();
    }

    // --- AJOUT : Déclaration de 'tickers' en dehors du try ---
    // Cela permet au 'catch' d'y accéder en cas d'erreur globale
    Set<String> tickers = {};
    // --- FIN AJOUT ---

    try {
      // 1. Aplatir tous les actifs et extraire les tickers uniques
      List<Asset> allAssets = [];
      for (var inst in activePortfolio.institutions) {
        for (var acc in inst.accounts) {
          allAssets.addAll(acc.assets);
        }
      }
      tickers = // <-- Assignation (au lieu de 'final')
      allAssets.map((a) => a.ticker).where((t) => t.isNotEmpty).toSet();

      if (tickers.isEmpty) {
        // CORRIGÉ : Constructeur par défaut
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
        final source = result.source;

        if (newPrice != null) {
          // Si un prix est trouvé (FMP, Yahoo, ou Cache),
          // on vérifie s'il doit être mis à jour dans Hive.
          final metadata = repository.getOrCreateAssetMetadata(result.ticker);
          if (metadata.currentPrice != newPrice) {
            metadata.updatePrice(newPrice);
            saveFutures.add(repository.saveAssetMetadata(metadata));

            // Compter la source de la mise à jour
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
      // CORRIGÉ : Constructeur avec les tickers qui ont échoué
      return SyncResult(
        failedTickers: tickers.toList(), // Retourne tous les tickers comme échoués
      );
    }
  }
}