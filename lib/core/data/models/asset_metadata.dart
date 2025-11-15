// lib/core/data/models/asset_metadata.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:hive/hive.dart';

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
  /// Devise du prix (ex: "USD", "EUR")
  @HiveField(5)
  String priceCurrency;
  // --- FIN NOUVEAU ---

  AssetMetadata({
    required this.ticker,
    this.currentPrice = 0.0,
    this.priceCurrency = 'EUR', // <-- MODIFIÉ (défaut)
    this.estimatedAnnualYield = 0.0,
    DateTime? lastUpdated,
    this.isManualYield = false,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Met à jour le prix actuel
  void updatePrice(double newPrice, String newCurrency) {
    currentPrice = newPrice;
    priceCurrency = newCurrency; // <-- MODIFIÉ
    lastUpdated = DateTime.now();
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
    String? priceCurrency, // <-- MODIFIÉ
    double? estimatedAnnualYield,
    DateTime? lastUpdated,
    bool? isManualYield,
  }) {
    return AssetMetadata(
      ticker: ticker ?? this.ticker,
      currentPrice: currentPrice ?? this.currentPrice,
      priceCurrency: priceCurrency ?? this.priceCurrency, // <-- MODIFIÉ
      estimatedAnnualYield: estimatedAnnualYield ?? this.estimatedAnnualYield,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isManualYield: isManualYield ?? this.isManualYield,
    );
  }
}