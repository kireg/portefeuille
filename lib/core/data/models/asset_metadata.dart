// lib/core/data/models/asset_metadata.dart

import 'package:hive/hive.dart';
import 'sync_status.dart';

part 'asset_metadata.g.dart';

/// Métadonnées d'un actif, partagées entre tous les comptes.
/// Stocke le prix actuel et le rendement annuel estimé.
@HiveType(typeId: 9) // IMPORTANT: Utiliser un typeId non utilisé
class AssetMetadata {
  /// Identifiant unique de l'actif (ticker)
  @HiveField(0)
  final String ticker;

  /// Prix actuel de l'actif (mis à jour lors de la synchronisation)
  @HiveField(1)
  double currentPrice;

  /// Rendement annuel estimé en pourcentage (ex: 3.5 pour 3.5%)
  /// Peut être saisi manuellement ou récupéré via API
  @HiveField(2)
  double estimatedAnnualYield;

  /// Date de la dernière mise à jour des métadonnées
  @HiveField(3)
  DateTime lastUpdated;

  /// Indique si le rendement a été saisi manuellement par l'utilisateur
  /// Si true, la synchronisation ne remplace pas cette valeur
  @HiveField(4)
  bool isManualYield;

  // --- NOUVEAU CHAMP ---
  /// Devise du prix (ex: "USD", "EUR") - Nullable pour compatibilité
  @HiveField(5)
  String? priceCurrency;
  // --- FIN NOUVEAU ---

  // --- NOUVEAUX CHAMPS POUR LA SYNCHRONISATION ---
  /// Statut de synchronisation de l'actif
  @HiveField(6)
  SyncStatus? syncStatus;

  /// Date de la dernière tentative de synchronisation
  @HiveField(7)
  DateTime? lastSyncAttempt;

  /// Message d'erreur de la dernière synchronisation (si échec)
  @HiveField(8)
  String? syncErrorMessage;

  /// Code ISIN de l'actif (si disponible)
  @HiveField(9)
  String? isin;

  /// Type d'actif détaillé (ex: "Large Cap", "Government Bond", etc.)
  @HiveField(10)
  String? assetTypeDetailed;

  /// Source de la dernière synchronisation (ex: "FMP", "Yahoo")
  @HiveField(11)
  String? lastSyncSource;
  // --- FIN NOUVEAUX CHAMPS ---

  // Getters pour garantir des valeurs par défaut
  String get activeCurrency => priceCurrency ?? 'EUR';
  SyncStatus get activeStatus => syncStatus ?? SyncStatus.never;

  AssetMetadata({
    required this.ticker,
    this.currentPrice = 0.0,
    this.priceCurrency = 'EUR', // <-- MODIFIÉ (défaut)
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

  /// Met à jour le prix actuel
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

  /// Marque la synchronisation comme échouée
  void markSyncError(String errorMessage) {
    lastSyncAttempt = DateTime.now();
    syncStatus = SyncStatus.error;
    syncErrorMessage = errorMessage;
  }

  /// Marque l'actif comme manuel (pas de synchro auto)
  void markAsManual() {
    syncStatus = SyncStatus.manual;
  }

  /// Met à jour le rendement annuel estimé
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
}
