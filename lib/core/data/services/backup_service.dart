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
  // NOTE: _allBoxNames n'est plus utilisé pour l'itération générique,
  // mais gardé en référence ou pour d'autres usages futurs.
  // ignore: unused_field
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
      // NOTE: Sur le Web, il est CRITIQUE d'utiliser le bon type générique <T> correspondant
      // à l'ouverture de la box (Hive.openBox<T>). Sinon, Hive lance une erreur
      // "Box is already open and of type Box<T>".
      
      await Hive.box<Portfolio>(AppConstants.kPortfolioBoxName).clear();
      await Hive.box<Transaction>(AppConstants.kTransactionBoxName).clear();
      await Hive.box<AssetMetadata>(AppConstants.kAssetMetadataBoxName).clear();
      await Hive.box<PriceHistoryPoint>(AppConstants.kPriceHistoryBoxName).clear();
      await Hive.box<ExchangeRateHistory>(AppConstants.kExchangeRateHistoryBoxName).clear();
      await Hive.box<SyncLog>(AppConstants.kSyncLogsBoxName).clear();
      await Hive.box(AppConstants.kSettingsBoxName).clear(); // Settings est ouvert sans type (dynamic)

      // 3. Vider la clé API (Safe)
      try {
        await _secureStorage.delete(key: _kFmpApiKey);
      } catch (e) {
        debugPrint("⚠️ Warning: Impossible de supprimer la clé API du SecureStorage: $e");
      }

      // 4. Remplir les box avec les nouvelles données
      // On réutilise les types explicites pour éviter les erreurs de type sur le Web.
      if (backupData.portfolios.isNotEmpty) {
        await Hive.box<Portfolio>(AppConstants.kPortfolioBoxName).addAll(backupData.portfolios);
      }

      if (backupData.transactions.isNotEmpty) {
        await Hive.box<Transaction>(AppConstants.kTransactionBoxName).addAll(backupData.transactions);
      }

      if (backupData.assetMetadata.isNotEmpty) {
        await Hive.box<AssetMetadata>(AppConstants.kAssetMetadataBoxName).addAll(backupData.assetMetadata);
      }

      if (backupData.priceHistory.isNotEmpty) {
        await Hive.box<PriceHistoryPoint>(AppConstants.kPriceHistoryBoxName).addAll(backupData.priceHistory);
      }

      if (backupData.exchangeRateHistory.isNotEmpty) {
        await Hive.box<ExchangeRateHistory>(AppConstants.kExchangeRateHistoryBoxName).addAll(backupData.exchangeRateHistory);
      }

      if (backupData.syncLogs.isNotEmpty) {
        await Hive.box<SyncLog>(AppConstants.kSyncLogsBoxName).addAll(backupData.syncLogs);
      }

      if (backupData.settings.isNotEmpty) {
        await Hive.box(AppConstants.kSettingsBoxName).putAll(backupData.settings);
      }

      if (backupData.settings.isNotEmpty) {
        await Hive.box(AppConstants.kSettingsBoxName).putAll(backupData.settings);
      }

      // 5. Ré-écrire la clé API si elle existe (Safe)
      if (backupData.fmpApiKey != null && backupData.fmpApiKey!.isNotEmpty) {
        try {
          await _secureStorage.write(key: _kFmpApiKey, value: backupData.fmpApiKey);
        } catch (e) {
          debugPrint("⚠️ Warning: Impossible d'écrire la clé API dans SecureStorage: $e");
        }
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