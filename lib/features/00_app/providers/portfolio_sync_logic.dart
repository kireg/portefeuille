// lib/features/00_app/providers/portfolio_sync_logic.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';

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
  final _uuid = const Uuid();

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
        final metadata = repository.getOrCreateAssetMetadata(result.ticker);

        if (newPrice != null) {
          // Prix récupéré avec succès
          // On vérifie si le prix OU la devise a changé
          if (metadata.currentPrice != newPrice ||
              metadata.priceCurrency != newCurrency) {
            // Mise à jour avec la source
            metadata.updatePrice(newPrice, newCurrency, source: source.name);

            saveFutures.add(repository.saveAssetMetadata(metadata));

            // Enregistrer le log de succès
            final syncLog = SyncLog.success(
              id: _uuid.v4(),
              ticker: result.ticker,
              source: source.name,
              price: newPrice,
              currency: newCurrency,
            );
            saveFutures.add(repository.addSyncLog(syncLog));

            if (source == ApiSource.Fmp) fmpUpdates++;
            if (source == ApiSource.Yahoo) yahooUpdates++;
          } else if (source == ApiSource.Cache) {
            cacheUpdates++;
          }
        } else {
          // Échec de récupération : source == ApiSource.None
          // Déterminer si c'est un actif non synchronisable ou une vraie erreur
          final ticker = result.ticker.toUpperCase();

          // Liste de patterns pour actifs non synchronisables
          final unsyncablePatterns = [
            'FONDS',
            'EURO',
            'SCPI',
            'PEL',
            'CEL',
            'LIVRET',
          ];

          final isUnsyncable =
              unsyncablePatterns.any((pattern) => ticker.contains(pattern));

          if (isUnsyncable) {
            // Actif non synchronisable (fonds en euros, etc.)
            metadata.syncStatus = SyncStatus.unsyncable;
            metadata.lastSyncAttempt = DateTime.now();
            metadata.syncErrorMessage =
                'Actif non coté : synchronisation automatique impossible';

            // Log d'erreur pour actif non synchronisable
            final syncLog = SyncLog.error(
              id: _uuid.v4(),
              ticker: result.ticker,
              errorMessage:
                  'Actif non coté (${ticker}): synchronisation automatique impossible',
            );
            saveFutures.add(repository.addSyncLog(syncLog));
          } else {
            // Vraie erreur de synchronisation
            metadata.markSyncError(
                'Impossible de récupérer le prix depuis les APIs');

            // Log d'erreur
            final syncLog = SyncLog.error(
              id: _uuid.v4(),
              ticker: result.ticker,
              errorMessage:
                  'Échec de récupération du prix depuis toutes les APIs',
            );
            saveFutures.add(repository.addSyncLog(syncLog));
          }

          saveFutures.add(repository.saveAssetMetadata(metadata));
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
