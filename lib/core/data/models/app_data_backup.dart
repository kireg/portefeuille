// lib/core/data/models/app_data_backup.dart

// Imports de tous vos modèles
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/price_history_point.dart';
import 'package:portefeuille/core/data/models/exchange_rate_history.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';

/// Un modèle "wrapper" qui contient toutes les données de l'application
/// pour une sérialisation JSON facile.
class AppDataBackup {
  final List<Portfolio> portfolios;
  final List<Transaction> transactions;
  final List<AssetMetadata> assetMetadata;
  final List<PriceHistoryPoint> priceHistory;
  final List<ExchangeRateHistory> exchangeRateHistory;
  final List<SyncLog> syncLogs;

  // Les settings sont une simple Map<String, dynamic>
  final Map<String, dynamic> settings;

  // La clé API est stockée séparément
  final String? fmpApiKey;

  AppDataBackup({
    required this.portfolios,
    required this.transactions,
    required this.assetMetadata,
    required this.priceHistory,
    required this.exchangeRateHistory,
    required this.syncLogs,
    required this.settings,
    this.fmpApiKey,
  });

  // Méthode pour convertir l'objet entier en JSON
  Map<String, dynamic> toJson() {
    return {
      'portfolios': portfolios.map((e) => e.toJson()).toList(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'assetMetadata': assetMetadata.map((e) => e.toJson()).toList(),
      'priceHistory': priceHistory.map((e) => e.toJson()).toList(),
      'exchangeRateHistory': exchangeRateHistory.map((e) => e.toJson()).toList(),
      'syncLogs': syncLogs.map((e) => e.toJson()).toList(),
      'settings': settings,
      'fmpApiKey': fmpApiKey,
    };
  }

  // Méthode pour créer l'objet depuis un JSON
  factory AppDataBackup.fromJson(Map<String, dynamic> json) {
    return AppDataBackup(
      portfolios: (json['portfolios'] as List<dynamic>? ?? [])
          .map((e) => Portfolio.fromJson(e as Map<String, dynamic>))
          .toList(),
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      assetMetadata: (json['assetMetadata'] as List<dynamic>? ?? [])
          .map((e) => AssetMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
      priceHistory: (json['priceHistory'] as List<dynamic>? ?? [])
          .map((e) => PriceHistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      exchangeRateHistory: (json['exchangeRateHistory'] as List<dynamic>? ?? [])
          .map((e) => ExchangeRateHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      syncLogs: (json['syncLogs'] as List<dynamic>? ?? [])
          .map((e) => SyncLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: (json['settings'] as Map<String, dynamic>? ?? {}),
      fmpApiKey: json['fmpApiKey'] as String?,
    );
  }
}