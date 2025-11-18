// lib/core/data/models/sync_log.dart

import 'package:hive/hive.dart';
import 'package:portefeuille/core/utils/enum_helpers.dart'; // NOUVEL IMPORT
import 'sync_status.dart';

part 'sync_log.g.dart';

@HiveType(typeId: 13)
class SyncLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String ticker;

  @HiveField(3)
  final SyncStatus status;

  @HiveField(4)
  final String message;

  @HiveField(5)
  final String? source;

  @HiveField(6)
  final double? price;

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

  // ... (vos méthodes toMap, success, et error restent inchangées) ...

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

  // --- NOUVELLES MÉTHODES JSON ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'ticker': ticker,
      'status': enumToString(status),
      'message': message,
      'source': source,
      'price': price,
      'currency': currency,
    };
  }

  factory SyncLog.fromJson(Map<String, dynamic> json) {
    return SyncLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ticker: json['ticker'] as String,
      status: enumFromString(
        SyncStatus.values,
        json['status'],
        fallback: SyncStatus.error,
      ),
      message: json['message'] as String,
      source: json['source'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
// --- FIN NOUVELLES MÉTHODES JSON ---
}