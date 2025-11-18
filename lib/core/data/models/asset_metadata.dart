// lib/core/data/models/asset_metadata.dart

import 'package:hive/hive.dart';
import 'package:portefeuille/core/utils/enum_helpers.dart'; // NOUVEL IMPORT
import 'sync_status.dart';

part 'asset_metadata.g.dart';

@HiveType(typeId: 9)
class AssetMetadata {
  @HiveField(0)
  final String ticker;

  @HiveField(1)
  double currentPrice;

  @HiveField(2)
  double estimatedAnnualYield;

  @HiveField(3)
  DateTime lastUpdated;

  @HiveField(4)
  bool isManualYield;

  @HiveField(5)
  String? priceCurrency;

  @HiveField(6)
  SyncStatus? syncStatus;

  @HiveField(7)
  DateTime? lastSyncAttempt;

  @HiveField(8)
  String? syncErrorMessage;

  @HiveField(9)
  String? isin;

  @HiveField(10)
  String? assetTypeDetailed;

  @HiveField(11)
  String? lastSyncSource;

  String get activeCurrency => priceCurrency ?? 'EUR';
  SyncStatus get activeStatus => syncStatus ?? SyncStatus.never;

  AssetMetadata({
    required this.ticker,
    this.currentPrice = 0.0,
    this.priceCurrency = 'EUR',
    this.estimatedAnnualYield = 0.0,
    DateTime? lastUpdated,
    this.isManualYield = false,
    this.syncStatus = SyncStatus.never,
    this.lastSyncAttempt,
    this.syncErrorMessage,
    this.isin,
    this.assetTypeDetailed,
    this.lastSyncSource,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // ... (toutes vos méthodes existantes : updatePrice, markSyncError, etc. restent inchangées) ...

  void updatePrice(double newPrice, String newCurrency, {String? source}) {
    currentPrice = newPrice;
    priceCurrency = newCurrency;
    lastUpdated = DateTime.now();
    lastSyncAttempt = DateTime.now();
    syncStatus = SyncStatus.synced;
    syncErrorMessage = null;
    if (source != null) {
      lastSyncSource = source;
    }
  }

  void markSyncError(String errorMessage) {
    lastSyncAttempt = DateTime.now();
    syncStatus = SyncStatus.error;
    syncErrorMessage = errorMessage;
  }

  void markAsManual() {
    syncStatus = SyncStatus.manual;
  }

  void updateYield(double newYield, {bool isManual = true}) {
    estimatedAnnualYield = newYield;
    isManualYield = isManual;
    lastUpdated = DateTime.now();
  }

  AssetMetadata copyWith({
    String? ticker,
    double? currentPrice,
    String? priceCurrency,
    double? estimatedAnnualYield,
    DateTime? lastUpdated,
    bool? isManualYield,
    SyncStatus? syncStatus,
    DateTime? lastSyncAttempt,
    String? syncErrorMessage,
    String? isin,
    String? assetTypeDetailed,
    String? lastSyncSource,
  }) {
    return AssetMetadata(
      ticker: ticker ?? this.ticker,
      currentPrice: currentPrice ?? this.currentPrice,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      estimatedAnnualYield: estimatedAnnualYield ?? this.estimatedAnnualYield,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isManualYield: isManualYield ?? this.isManualYield,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncErrorMessage: syncErrorMessage ?? this.syncErrorMessage,
      isin: isin ?? this.isin,
      assetTypeDetailed: assetTypeDetailed ?? this.assetTypeDetailed,
      lastSyncSource: lastSyncSource ?? this.lastSyncSource,
    );
  }

  // --- NOUVELLES MÉTHODES JSON ---
  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'currentPrice': currentPrice,
      'estimatedAnnualYield': estimatedAnnualYield,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isManualYield': isManualYield,
      'priceCurrency': priceCurrency,
      'syncStatus': enumToString(syncStatus),
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'syncErrorMessage': syncErrorMessage,
      'isin': isin,
      'assetTypeDetailed': assetTypeDetailed,
      'lastSyncSource': lastSyncSource,
    };
  }

  factory AssetMetadata.fromJson(Map<String, dynamic> json) {
    return AssetMetadata(
      ticker: json['ticker'] as String,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      estimatedAnnualYield:
      (json['estimatedAnnualYield'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
      isManualYield: json['isManualYield'] as bool? ?? false,
      priceCurrency: json['priceCurrency'] as String? ?? 'EUR',
      syncStatus: enumFromString(
        SyncStatus.values,
        json['syncStatus'],
        fallback: SyncStatus.never,
      ),
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'] as String)
          : null,
      syncErrorMessage: json['syncErrorMessage'] as String?,
      isin: json['isin'] as String?,
      assetTypeDetailed: json['assetTypeDetailed'] as String?,
      lastSyncSource: json['lastSyncSource'] as String?,
    );
  }
// --- FIN NOUVELLES MÉTHODES JSON ---
}