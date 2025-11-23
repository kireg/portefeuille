import 'package:portefeuille/core/data/models/asset_metadata.dart';

List<AssetMetadata> getDemoMetadata() {
  return [
    AssetMetadata(
      ticker: 'CW8.PA',
      currentPrice: 500.0,
      estimatedAnnualYield: 0.085, // 8.5% annuel
      lastUpdated: DateTime(2025, 11, 12),
      isManualYield: false,
    ),
    AssetMetadata(
      ticker: 'MC.PA',
      currentPrice: 750.0,
      estimatedAnnualYield: 0.020, // Dividende ~2%
      lastUpdated: DateTime(2025, 11, 12),
      isManualYield: false,
    ),
    AssetMetadata(
      ticker: 'TTE.PA',
      currentPrice: 65.0,
      estimatedAnnualYield: 0.055, // Dividende élevé ~5.5%
      lastUpdated: DateTime(2025, 11, 12),
      isManualYield: false,
    ),
    AssetMetadata(
      ticker: 'AAPL',
      currentPrice: 220.0,
      estimatedAnnualYield: 0.005, // Dividende faible ~0.5%
      lastUpdated: DateTime(2025, 11, 12),
      isManualYield: false,
    ),
    AssetMetadata(
      ticker: 'MSFT',
      currentPrice: 430.0,
      estimatedAnnualYield: 0.008, // Dividende faible ~0.8%
      lastUpdated: DateTime(2025, 11, 12),
      isManualYield: false,
    ),
    AssetMetadata(
      ticker: 'BTC-EUR',
      currentPrice: 75000.0,
      estimatedAnnualYield: 0.0, // Pas de rendement
      lastUpdated: DateTime(2025, 11, 12),
      isManualYield: false,
    ),
    AssetMetadata(
      ticker: 'ETH-EUR',
      currentPrice: 3000.0,
      estimatedAnnualYield: 0.0, // Pas de rendement
      lastUpdated: DateTime(2025, 11, 12),
      isManualYield: false,
    ),
    AssetMetadata(
      ticker: 'FONDS-EUROS',
      currentPrice: 1.025,
      estimatedAnnualYield: 0.025, // 2.5% garanti
      lastUpdated: DateTime(2025, 11, 12),
      isManualYield: true, // Saisi manuellement
    ),
  ];
}
