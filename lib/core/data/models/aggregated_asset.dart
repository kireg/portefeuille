// lib/core/data/models/aggregated_asset.dart
// NOUVEAU FICHIER

import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/data/models/asset_type.dart'; // AJOUT

/// Modèle pour la vue "Synthèse des Actifs".
/// Toutes les valeurs monétaires de ce modèle sont CONVERTIES
/// dans la devise de base de l'utilisateur (ex: EUR).
class AggregatedAsset {
  final String ticker;
  final String name;
  final double quantity;

  /// PRU converti dans la devise de base
  final double averagePrice;

  /// Prix actuel converti dans la devise de base
  final double currentPrice;

  /// Valeur totale convertie dans la devise de base
  final double totalValue;

  /// P/L convertie dans la devise de base
  final double profitAndLoss;

  /// P/L en pourcentage (indépendant de la devise)
  final double profitAndLossPercentage;

  /// Rendement annuel (indépendant de la devise)
  final double estimatedAnnualYield;

  /// Métadonnées pour l'affichage du statut
  final AssetMetadata? metadata;

  /// Devise de l'actif (ex: USD)
  final String assetCurrency;

  /// Devise de base (ex: EUR)
  final String baseCurrency;

  /// Type de l'actif
  final AssetType type;

  AggregatedAsset({
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.totalValue,
    required this.profitAndLoss,
    required this.profitAndLossPercentage,
    required this.estimatedAnnualYield,
    this.metadata,
    required this.assetCurrency,
    required this.baseCurrency,
    this.type = AssetType.Other,
  });

  SyncStatus get syncStatus => metadata?.syncStatus ?? SyncStatus.never;
}