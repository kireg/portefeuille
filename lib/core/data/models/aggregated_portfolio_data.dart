// lib/core/data/models/aggregated_portfolio_data.dart
// NOUVEAU FICHIER

import 'package:portefeuille/core/data/models/aggregated_asset.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

/// Un objet de données simple pour contenir tous les résultats
/// des calculs d'agrégation effectués par le [PortfolioCalculationService].
class AggregatedPortfolioData {
  /// La devise de base utilisée pour ces calculs (ex: "EUR").
  final String baseCurrency;

  /// La valeur totale du portefeuille, convertie dans la devise de base.
  final double totalValue;
  /// La P/L totale du portefeuille, convertie.
  final double totalPL;
  /// Le capital investi total, converti.
  final double totalInvested;

  /// Map [accountId] -> Valeur totale convertie
  final Map<String, double> accountValues;
  /// Map [accountId] -> P/L convertie
  final Map<String, double> accountPLs;
  /// Map [accountId] -> Capital investi converti
  final Map<String, double> accountInvested;

  /// Map [asset.id] -> Valeur totale convertie (pour AssetListItem)
  final Map<String, double> assetTotalValues;
  /// Map [asset.id] -> P/L convertie (pour AssetListItem)
  final Map<String, double> assetPLs;

  /// Liste des actifs agrégés par ticker (pour SyntheseView)
  final List<AggregatedAsset> aggregatedAssets;

  /// Map des valeurs agrégées par type (pour AllocationChart)
  final Map<AssetType, double> valueByAssetType;

  /// Rendement annuel estimé du portefeuille (pondéré)
  final double estimatedAnnualYield;

  /// Liste des devises pour lesquelles la conversion a échoué (fallback à 1.0)
  final List<String> failedConversions;

  AggregatedPortfolioData({
    required this.baseCurrency,
    required this.totalValue,
    required this.totalPL,
    required this.totalInvested,
    required this.accountValues,
    required this.accountPLs,
    required this.accountInvested,
    required this.assetTotalValues,
    required this.assetPLs,
    required this.aggregatedAssets,
    required this.valueByAssetType,
    required this.estimatedAnnualYield,
    this.failedConversions = const [],
  });

  /// Construit une instance vide par défaut.
  static final AggregatedPortfolioData empty = AggregatedPortfolioData(
    baseCurrency: 'EUR',
    totalValue: 0.0,
    totalPL: 0.0,
    totalInvested: 0.0,
    accountValues: {},
    accountPLs: {},
    accountInvested: {},
    assetTotalValues: {},
    assetPLs: {},
    aggregatedAssets: [],
    valueByAssetType: {},
    estimatedAnnualYield: 0.0,
    failedConversions: [],
  );
}