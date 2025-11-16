// lib/core/data/models/sync_log.dart

import 'package:hive/hive.dart';
import 'sync_status.dart';

part 'sync_log.g.dart';

/// Log d'une tentative de synchronisation
@HiveType(typeId: 13)
class SyncLog {
  /// ID unique du log
  @HiveField(0)
  final String id;

  /// Date et heure de la tentative
  @HiveField(1)
  final DateTime timestamp;

  /// Ticker de l'actif concerné
  @HiveField(2)
  final String ticker;

  /// Statut de la synchronisation
  @HiveField(3)
  final SyncStatus status;

  /// Message détaillé (erreur ou succès)
  @HiveField(4)
  final String message;

  /// Source utilisée (FMP, Yahoo, CoinGecko, etc.)
  @HiveField(5)
  final String? source;

  /// Prix récupéré (si succès)
  @HiveField(6)
  final double? price;

  /// Devise du prix (si succès)
  @HiveField(7)
  final String? currency;

  SyncLog({
    required this.id,
    required this.timestamp,
    required this.ticker,
    required this.status,
    required this.message,
    this.source,
    this.price,
    this.currency,
  });

  /// Convertit le log en Map (pour export CSV/JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'ticker': ticker,
      'status': status.displayName,
      'message': message,
      'source': source ?? 'N/A',
      'price': price?.toString() ?? 'N/A',
      'currency': currency ?? 'N/A',
    };
  }

  /// Crée un log de succès
  factory SyncLog.success({
    required String id,
    required String ticker,
    required String source,
    required double price,
    required String currency,
  }) {
    return SyncLog(
      id: id,
      timestamp: DateTime.now(),
      ticker: ticker,
      status: SyncStatus.synced,
      message: 'Prix synchronisé avec succès depuis $source',
      source: source,
      price: price,
      currency: currency,
    );
  }

  /// Crée un log d'erreur
  factory SyncLog.error({
    required String id,
    required String ticker,
    required String errorMessage,
    String? attemptedSource,
  }) {
    return SyncLog(
      id: id,
      timestamp: DateTime.now(),
      ticker: ticker,
      status: SyncStatus.error,
      message: errorMessage,
      source: attemptedSource,
    );
  }
}
