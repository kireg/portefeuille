import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. IMPORTS CORE UI
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';

// 2. IMPORTS DATA & PROVIDERS
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/features/00_app/models/background_activity.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/06_settings/ui/settings_screen.dart';

class DashboardAppBar extends StatefulWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
  });

  @override
  State<DashboardAppBar> createState() => _DashboardAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _DashboardAppBarState extends State<DashboardAppBar> {
  bool _isSnackBarVisible = false;

  Map<String, int> _getSyncStats(PortfolioProvider portfolio) {
    final activePortfolio = portfolio.activePortfolio;
    if (activePortfolio == null) return {'synced': 0, 'errors': 0, 'total': 0};

    // Récupérer tous les tickers du portefeuille actif
    final activeTickers = <String>{};
    for (final institution in activePortfolio.institutions) {
      for (final account in institution.accounts) {
        for (final asset in account.assets) {
          activeTickers.add(asset.ticker);
        }
      }
    }

    final metadata = portfolio.allMetadata;
    int synced = 0;
    int errors = 0;
    int manual = 0;
    int unsyncable = 0;
    
    // Ne compter que les métadonnées des actifs présents dans le portefeuille actif
    for (final ticker in activeTickers) {
      final meta = metadata[ticker];
      if (meta == null) continue;

      final status = meta.syncStatus ?? SyncStatus.never;
      switch (status) {
        case SyncStatus.synced: synced++; break;
        case SyncStatus.error: errors++; break;
        case SyncStatus.manual: manual++; break;
        case SyncStatus.unsyncable: unsyncable++; break;
        default: break;
      }
    }
    
    final total = activeTickers.length - unsyncable;
    return {
      'synced': synced + manual,
      'errors': errors,
      'total': total,
    };
  }

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = context.watch<PortfolioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final portfolio = portfolioProvider.activePortfolio;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleSyncMessage(context, portfolioProvider);
    });

    // 1. Cas : Aucun portefeuille
    if (portfolio == null) {
      return AppBar(
        title: Text('Portefeuille', style: AppTypography.h3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () => _openSettings(context),
          ),
        ],
      );
    }

    // 2. Cas Normal : Barre Flottante
    return SafeArea(
      bottom: false,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS / 2,
        ),
        child: AppCard(
          isGlass: true,
          withShadow: true,
          backgroundColor: AppColors.surface.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- Sélecteur de Portefeuille (Aligné à gauche) ---
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                        child: _buildPortfolioSelector(portfolioProvider, portfolio),
                      ),
                    );
                  },
                ),
              ),

              // --- Statut + Settings (Aligné à droite) ---
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusIndicator(settingsProvider, portfolioProvider),
                  IconButton(
                    icon: Icon(
                      settingsProvider.isPrivacyMode ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => settingsProvider.togglePrivacyMode(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  // ... (Le reste des méthodes _buildStatusIndicator, _buildPortfolioSelector, etc. reste identique) ...
  // Je ne répète pas les fonctions privées inchangées pour alléger la réponse,
  // mais elles doivent rester dans la classe _DashboardAppBarState.

  Widget _buildStatusIndicator(SettingsProvider settings, PortfolioProvider portfolio) {
    // ... (Code existant inchangé)
    final textStyle = AppTypography.caption.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
    );

    final stats = _getSyncStats(portfolio);
    final totalCount = stats['total']!;
    final errorsCount = stats['errors']!;
    final syncedCount = stats['synced']!;

    Widget content;

    if (portfolio.activity is Syncing) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          const SizedBox(width: 6),
          Text("Synchro...", style: textStyle),
        ],
      );
    } else if (settings.isOnlineMode) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_queue_outlined, size: 16, color: textStyle.color),
          if (totalCount == 0) ...[
            const SizedBox(width: 6),
            Text("En ligne", style: textStyle),
          ],
          if (totalCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: errorsCount > 0 ? AppColors.error : AppColors.success,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$syncedCount/$totalCount',
                style: textStyle.copyWith(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 16, color: textStyle.color?.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text("Hors ligne", style: textStyle),
        ],
      );
    }

    return InkWell(
      onTap: () => _showStatusMenu(context, settings, portfolio),
      borderRadius: BorderRadius.circular(AppDimens.radiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: content,
      ),
    );
  }

  Widget _buildPortfolioSelector(PortfolioProvider provider, Portfolio activePortfolio) {
    // ... (Code existant inchangé)
    return PopupMenuButton<Portfolio>(
      color: AppColors.surfaceLight,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusM)),
      onSelected: (portfolio) => provider.setActivePortfolio(portfolio.id),
      itemBuilder: (context) {
        return provider.portfolios.map((portfolio) {
          final isSelected = portfolio.id == activePortfolio.id;
          return PopupMenuItem<Portfolio>(
            value: portfolio,
            child: Row(
              children: [
                Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(portfolio.name, style: isSelected ? AppTypography.bodyBold : AppTypography.body),
              ],
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                activePortfolio.name,
                style: AppTypography.h3.copyWith(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _handleSyncMessage(BuildContext context, PortfolioProvider provider) {
    // ... (Code existant inchangé)
    final message = provider.syncMessage;
    if (message != null && !_isSnackBarVisible) {
      setState(() => _isSnackBarVisible = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: AppTypography.body),
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 4),
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusS)),
        ),
      ).closed.then((_) {
        if (mounted) {
          provider.clearSyncMessage();
          setState(() => _isSnackBarVisible = false);
        }
      });
    }
  }

  void _showStatusMenu(BuildContext context, SettingsProvider settings, PortfolioProvider portfolio) {
    // ... (Code existant inchangé)
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(settings.isOnlineMode ? Icons.cloud_off_outlined : Icons.cloud_queue_outlined, color: AppColors.textPrimary),
              title: Text(settings.isOnlineMode ? 'Passer "Hors ligne"' : 'Passer "En ligne"', style: AppTypography.body),
              onTap: () { Navigator.of(ctx).pop(); _confirmToggleOnline(context, settings); },
            ),
            if (settings.isOnlineMode)
              ListTile(
                leading: const Icon(Icons.sync, color: AppColors.textPrimary),
                title: Text('Forcer la synchronisation', style: AppTypography.body),
                subtitle: Text('Vide le cache et recharge les prix.', style: AppTypography.caption),
                onTap: () { Navigator.of(ctx).pop(); _confirmForceSync(context, portfolio); },
              ),
          ],
        );
      },
    );
  }

  void _confirmToggleOnline(BuildContext context, SettingsProvider settings) {
    // ... (Code existant inchangé)
    final isOnline = settings.isOnlineMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(isOnline ? 'Passer Hors ligne ?' : 'Passer En ligne ?', style: AppTypography.h3),
        content: Text(isOnline ? 'Les prix ne seront plus mis à jour.' : 'Les données réseau seront utilisées.', style: AppTypography.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () { settings.toggleOnlineMode(!isOnline); Navigator.of(ctx).pop(); },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmForceSync(BuildContext context, PortfolioProvider provider) {
    // ... (Code existant inchangé)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Forcer la synchronisation ?', style: AppTypography.h3),
        content: Text('Ceci consommera des crédits API.', style: AppTypography.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () { provider.forceSynchroniserLesPrix(); Navigator.of(ctx).pop(); },
            child: const Text('Forcer'),
          ),
        ],
      ),
    );
  }
}