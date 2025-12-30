import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

/// Utilitaires pour DashboardAppBar - Réduit la complexité du composant principal
class DashboardAppBarHelper {
  /// Récupère les stats de synchronisation
  static Map<String, int> getSyncStats(PortfolioProvider portfolio) {
    final activePortfolio = portfolio.activePortfolio;
    if (activePortfolio == null) return {'synced': 0, 'errors': 0, 'total': 0};

    final activeTickers = _getActiveTickers(activePortfolio);
    return _countSyncStatus(portfolio, activeTickers);
  }

  /// Récupère les assets avec problèmes de synchronisation
  static List<Map<String, dynamic>> getProblematicAssets(PortfolioProvider portfolio) {
    final activePortfolio = portfolio.activePortfolio;
    if (activePortfolio == null) return [];

    final activeTickers = _getActiveTickers(activePortfolio);
    final problematicAssets = <Map<String, dynamic>>[];
    final metadata = portfolio.allMetadata;

    for (final ticker in activeTickers) {
      final meta = metadata[ticker];
      if (meta != null && _isProblematic(meta)) {
        final name = _findAssetName(activePortfolio, ticker) ?? ticker;
        problematicAssets.add({
          'ticker': ticker,
          'name': name,
          'isin': meta.isin,
          'lastPrice': meta.currentPrice,
          'currency': meta.priceCurrency,
          'status': meta.syncStatus,
          'metadata': meta,
        });
      }
    }

    _sortProblematicAssets(problematicAssets);
    return problematicAssets;
  }

  static Set<String> _getActiveTickers(Portfolio portfolio) {
    final tickers = <String>{};
    for (final institution in portfolio.institutions) {
      for (final account in institution.accounts) {
        for (final asset in account.assets) {
          tickers.add(asset.ticker);
        }
      }
    }
    return tickers;
  }

  static Map<String, int> _countSyncStatus(PortfolioProvider portfolio, Set<String> activeTickers) {
    final metadata = portfolio.allMetadata;
    int synced = 0, errors = 0, manual = 0, unsyncable = 0, warnings = 0;

    for (final ticker in activeTickers) {
      final meta = metadata[ticker];
      if (meta == null) continue;

      final status = meta.syncStatus ?? SyncStatus.never;
      switch (status) {
        case SyncStatus.synced:
          synced++;
        case SyncStatus.error:
          errors++;
        case SyncStatus.manual:
          manual++;
        case SyncStatus.unsyncable:
          unsyncable++;
        case SyncStatus.pendingValidation:
          warnings++;
        default:
      }
    }

    final total = activeTickers.length - unsyncable;
    return {
      'synced': synced + manual,
      'errors': errors,
      'warnings': warnings,
      'total': total,
    };
  }

  static bool _isProblematic(AssetMetadata meta) {
    return meta.syncStatus == SyncStatus.error || meta.syncStatus == SyncStatus.pendingValidation;
  }

  static String? _findAssetName(Portfolio portfolio, String ticker) {
    for (final institution in portfolio.institutions) {
      for (final account in institution.accounts) {
        for (final asset in account.assets) {
          if (asset.ticker == ticker) return asset.name;
        }
      }
    }
    return null;
  }

  static void _sortProblematicAssets(List<Map<String, dynamic>> assets) {
    assets.sort((a, b) {
      final statusA = a['status'] as SyncStatus;
      final statusB = b['status'] as SyncStatus;
      if (statusA == SyncStatus.error && statusB != SyncStatus.error) return -1;
      if (statusA != SyncStatus.error && statusB == SyncStatus.error) return 1;
      return 0;
    });
  }
}
