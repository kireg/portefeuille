// lib/core/data/services/backup_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:portefeuille/core/data/models/app_data_backup.dart';
import 'package:portefeuille/core/utils/constants.dart';

// Imports des modèles
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/price_history_point.dart';
import 'package:portefeuille/core/data/models/exchange_rate_history.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';

class BackupService {
  final FlutterSecureStorage _secureStorage;

  // Clés des Box (doivent correspondre à votre main.dart)
  final List<String> _allBoxNames = [
    AppConstants.kPortfolioBoxName,
    AppConstants.kTransactionBoxName,
    AppConstants.kAssetMetadataBoxName,
    AppConstants.kPriceHistoryBoxName,
    AppConstants.kExchangeRateHistoryBoxName,
    AppConstants.kSyncLogsBoxName,
    AppConstants.kSettingsBoxName,
  ];

  // Clé sécurisée
  static const String _kFmpApiKey = 'fmpApiKey';

  BackupService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ??
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  /// Exporte TOUTES les données de l'application en une seule chaîne JSON.
  Future<String> exportData() async {
    try {
      // 1. Récupérer les données de toutes les box
      final portfolioBox = Hive.box<Portfolio>(AppConstants.kPortfolioBoxName);
      final transactionBox = Hive.box<Transaction>(AppConstants.kTransactionBoxName);
      final metadataBox = Hive.box<AssetMetadata>(AppConstants.kAssetMetadataBoxName);
      final priceHistoryBox = Hive.box<PriceHistoryPoint>(AppConstants.kPriceHistoryBoxName);
      final rateHistoryBox = Hive.box<ExchangeRateHistory>(AppConstants.kExchangeRateHistoryBoxName);
      final syncLogBox = Hive.box<SyncLog>(AppConstants.kSyncLogsBoxName);
      final settingsBox = Hive.box(AppConstants.kSettingsBoxName);

      // 2. Récupérer la clé API
      final apiKey = await _secureStorage.read(key: _kFmpApiKey);

      // 3. Créer l'objet de sauvegarde
      final backupData = AppDataBackup(
        portfolios: portfolioBox.values.toList(),
        transactions: transactionBox.values.toList(),
        assetMetadata: metadataBox.values.toList(),
        priceHistory: priceHistoryBox.values.toList(),
        exchangeRateHistory: rateHistoryBox.values.toList(),
        syncLogs: syncLogBox.values.toList(),
        settings: Map<String, dynamic>.from(settingsBox.toMap()),
        fmpApiKey: apiKey,
      );

      // 4. Convertir en JSON
      return jsonEncode(backupData.toJson());
    } catch (e) {
      debugPrint("Erreur lors de l'exportation: $e");
      rethrow;
    }
  }

  /// Importe les données depuis une chaîne JSON et remplace TOUTES les données actuelles.
  Future<void> importData(String jsonString) async {
    try {
      // 1. Décoder et valider le JSON
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final backupData = AppDataBackup.fromJson(jsonMap);

      // 2. Vider TOUTES les box
      for (final boxName in _allBoxNames) {
        await Hive.box(boxName).clear();
      }

      // 3. Vider la clé API
      await _secureStorage.delete(key: _kFmpApiKey);

      // 4. Remplir les box avec les nouvelles données
      // Utiliser 'putAll' ou 'addAll' pour de meilleures performances
      await Hive.box<Portfolio>(AppConstants.kPortfolioBoxName)
          .addAll(backupData.portfolios);

      await Hive.box<Transaction>(AppConstants.kTransactionBoxName)
          .addAll(backupData.transactions);

      await Hive.box<AssetMetadata>(AppConstants.kAssetMetadataBoxName)
          .addAll(backupData.assetMetadata);

      await Hive.box<PriceHistoryPoint>(AppConstants.kPriceHistoryBoxName)
          .addAll(backupData.priceHistory);

      await Hive.box<ExchangeRateHistory>(AppConstants.kExchangeRateHistoryBoxName)
          .addAll(backupData.exchangeRateHistory);

      await Hive.box<SyncLog>(AppConstants.kSyncLogsBoxName)
          .addAll(backupData.syncLogs);

      await Hive.box(AppConstants.kSettingsBoxName)
          .putAll(backupData.settings);

      // 5. Ré-écrire la clé API si elle existe
      if (backupData.fmpApiKey != null && backupData.fmpApiKey!.isNotEmpty) {
        await _secureStorage.write(key: _kFmpApiKey, value: backupData.fmpApiKey);
      }

    } catch (e) {
      debugPrint("Erreur lors de l'importation: $e");
      // Si l'import échoue, les données sont corrompues.
      // Il est préférable de laisser l'utilisateur avec une app vide
      // plutôt qu'une app à moitié importée.
      rethrow;
    }
  }
}