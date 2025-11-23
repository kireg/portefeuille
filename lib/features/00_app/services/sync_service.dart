// lib/features/00_app/services/sync_service.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';
import 'package:portefeuille/core/data/models/asset_type.dart'; // NOUVEL IMPORT
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:uuid/uuid.dart';

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
  bool get hasUpdates => updatedCount > 0;

  String getSummaryMessage() {
    if (updatedCount == 0 && failedCount == 0 && cacheUpdates == 0) {
      return "Synchro terminée : Aucun prix à mettre à jour.";
    }
    if (updatedCount == 0 && failedCount == 0 && cacheUpdates > 0) {
      return "Synchro terminée : Prix déjà à jour (Cache).";
    }

    final parts = <String>[];
    if (fmpUpdates > 0) parts.add("$fmpUpdates via FMP");
    if (yahooUpdates > 0) parts.add("$yahooUpdates via Yahoo");

    String summary = "Synchro : ${parts.join(', ')}.";
    if (failedCount > 0) {
      summary +=
      "\nÉchecs : $failedCount (${failedTickers.take(3).join(', ')}${failedCount > 3 ? ', ...' : ''})";
    }
    return summary;
  }
}

class SyncService {
  final PortfolioRepository _repository;
  final ApiService _apiService;
  final Uuid _uuid;

  SyncService({
    required PortfolioRepository repository,
    required ApiService apiService,
    Uuid? uuid,
  })  : _repository = repository,
        _apiService = apiService,
        _uuid = uuid ?? const Uuid();

  /// Force la synchronisation des prix en vidant d'abord le cache.
  Future<SyncResult> forceSync(Portfolio portfolio) async {
    _apiService.clearCache();
    return await synchronize(portfolio);
  }

  /// Synchronise les prix en utilisant la logique de fallback de l'ApiService.
  Future<SyncResult> synchronize(Portfolio portfolio) async {
    // Extraire tous les tickers uniques
    final tickers = _extractTickers(portfolio);
    if (tickers.isEmpty) {
      return SyncResult();
    }

    try {
      // Récupérer tous les prix en parallèle
      final results = await Future.wait(
        tickers.map(_apiService.getPrice),
      );

      // Traiter les résultats
      return await _processResults(results);
    } catch (e) {
      debugPrint("⚠️ Erreur lors de la synchronisation des prix : $e");
      return SyncResult(failedTickers: tickers.toList());
    }
  }

  Set<String> _extractTickers(Portfolio portfolio) {
    final tickers = <String>{};
    for (var inst in portfolio.institutions) {
      for (var acc in inst.accounts) {
        for (var asset in acc.assets) {
          // MODIFIÉ : On ignore le Crowdfunding pour la synchro des prix
          if (asset.ticker.isNotEmpty && asset.type != AssetType.RealEstateCrowdfunding) {
            tickers.add(asset.ticker);
          }
        }
      }
    }
    return tickers;
  }

  Future<SyncResult> _processResults(List<PriceResult> results) async {
    int fmpUpdates = 0;
    int yahooUpdates = 0;
    int cacheUpdates = 0;
    final failedTickers = <String>[];
    final saveFutures = <Future<void>>[];

    for (final result in results) {
      final metadata = _repository.getOrCreateAssetMetadata(result.ticker);

      if (result.price != null) {
        // Succès
        if (metadata.currentPrice != result.price ||
            metadata.priceCurrency != result.currency) {
          metadata.updatePrice(
            result.price!,
            result.currency,
            source: result.source.name,
          );

          saveFutures.add(_repository.saveAssetMetadata(metadata));
          saveFutures.add(_saveSyncLog(SyncLog.success(
            id: _uuid.v4(),
            ticker: result.ticker,
            source: result.source.name,
            price: result.price!,
            currency: result.currency,
          )));

          if (result.source == ApiSource.Fmp) fmpUpdates++;
          if (result.source == ApiSource.Yahoo) yahooUpdates++;
        } else if (result.source == ApiSource.Cache) {
          cacheUpdates++;
        }
      } else {
        // Échec
        final isUnsyncable = _isUnsyncableTicker(result.ticker);

        if (isUnsyncable) {
          metadata.syncStatus = SyncStatus.unsyncable;
          metadata.lastSyncAttempt = DateTime.now();
          metadata.syncErrorMessage =
          'Actif non coté : synchronisation automatique impossible';

          saveFutures.add(_saveSyncLog(SyncLog.error(
            id: _uuid.v4(),
            ticker: result.ticker,
            errorMessage:
            'Actif non coté (${result.ticker.toUpperCase()}): synchronisation automatique impossible',
          )));
        } else {
          metadata.markSyncError(
              'Impossible de récupérer le prix depuis les APIs');
          
          // Sauvegarde des erreurs détaillées
          if (result.errorDetails != null) {
            metadata.apiErrors = result.errorDetails;
          }

          saveFutures.add(_saveSyncLog(SyncLog.error(
            id: _uuid.v4(),
            ticker: result.ticker,
            errorMessage:
            'Échec de récupération du prix depuis toutes les APIs',
          )));
        }

        saveFutures.add(_repository.saveAssetMetadata(metadata));
        failedTickers.add(result.ticker);
      }
    }

    if (saveFutures.isNotEmpty) {
      await Future.wait(saveFutures);
    }

    return SyncResult(
      fmpUpdates: fmpUpdates,
      yahooUpdates: yahooUpdates,
      cacheUpdates: cacheUpdates,
      failedTickers: failedTickers,
    );
  }

  bool _isUnsyncableTicker(String ticker) {
    final upperTicker = ticker.toUpperCase();
    const unsyncablePatterns = [
      'FONDS',
      'EURO',
      'SCPI',
      'PEL',
      'CEL',
      'LIVRET',
    ];
    return unsyncablePatterns.any(upperTicker.contains);
  }

  Future<void> _saveSyncLog(SyncLog log) async {
    await _repository.addSyncLog(log);
  }
}