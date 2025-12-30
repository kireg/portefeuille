import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

import 'package:portefeuille/core/data/models/asset_metadata.dart';

import 'package:portefeuille/core/data/models/portfolio.dart';

class SyncAlertsCard extends StatelessWidget {
  const SyncAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<PortfolioProvider, ({Map<String, AssetMetadata> metadata, bool isProcessing, Portfolio? activePortfolio})>(
      selector: (context, provider) => (
        metadata: provider.allMetadata,
        isProcessing: provider.isProcessingInBackground,
        activePortfolio: provider.activePortfolio
      ),
      builder: (context, data, child) {
        final metadata = data.metadata;
        final isProcessing = data.isProcessing;
        final activePortfolio = data.activePortfolio;

        // Filtrer les actifs pour ne garder que ceux du portefeuille actif
        final activeTickers = <String>{};
        if (activePortfolio != null) {
          for (var inst in activePortfolio.institutions) {
            for (var acc in inst.accounts) {
              for (var asset in acc.assets) {
                if (asset.ticker.isNotEmpty) activeTickers.add(asset.ticker);
              }
            }
          }
        }

        final relevantMetadata = metadata.entries
            .where((entry) => activeTickers.contains(entry.key));

        // Filtrer les actifs par statut
        final assetsWithErrors = relevantMetadata
            .where((entry) => entry.value.syncStatus == SyncStatus.error)
            .toList();
        final neverSyncedCount = relevantMetadata
            .where((entry) => entry.value.syncStatus == SyncStatus.never)
            .length;
        final unsyncableCount = relevantMetadata
            .where((entry) => entry.value.syncStatus == SyncStatus.unsyncable)
            .length;
        final pendingValidation = relevantMetadata
            .where((entry) => entry.value.syncStatus == SyncStatus.pendingValidation)
            .toList();

        if (assetsWithErrors.isEmpty && neverSyncedCount == 0 && unsyncableCount == 0 && pendingValidation.isEmpty) {
          return const SizedBox.shrink();
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  AppIcon(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    backgroundColor: AppColors.warning.withValues(alpha: AppOpacities.lightOverlay),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Text('Alertes de synchronisation', style: AppTypography.h3),
                ],
              ),
              const SizedBox(height: AppDimens.paddingL),

              // 0. En attente de validation (Prioritaire)
              ...pendingValidation.map((entry) {
                final meta = entry.value;
                final oldPrice = meta.currentPrice;
                final newPrice = meta.pendingPrice ?? 0.0;
                final percent = oldPrice > 0 ? ((newPrice - oldPrice) / oldPrice * 100).toStringAsFixed(1) : "N/A";
                
                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: AppOpacities.lightOverlay),
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.price_change, color: AppColors.warning),
                          const SizedBox(width: AppDimens.paddingS),
                          Expanded(
                            child: Text(
                              "Validation requise : ${entry.key}",
                              style: AppTypography.bodyBold.copyWith(color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.paddingS),
                      Text(
                        "Le nouveau prix est beaucoup plus élevé (+$percent%).",
                        style: AppTypography.body,
                      ),
                      AppSpacing.gapXs,
                      Text(
                        "Ancien: $oldPrice ${meta.priceCurrency}  →  Nouveau: $newPrice ${meta.pendingPriceCurrency}",
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search, color: AppColors.primary),
                            onPressed: () => _searchAssetOnWeb(entry.key, meta.isin),
                            tooltip: 'Rechercher sur le web',
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.accent),
                            onPressed: () => _showUpdatePriceDialog(
                              context, 
                              Provider.of<PortfolioProvider>(context, listen: false), 
                              entry.key, 
                              meta.currentPrice
                            ),
                            tooltip: 'Corriger le prix',
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          TextButton(
                            onPressed: () {
                              meta.ignorePendingPrice();
                              Provider.of<PortfolioProvider>(context, listen: false).saveMetadata(meta);
                            },
                            child: const Text("IGNORER", style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          ElevatedButton(
                            onPressed: () {
                              meta.validatePendingPrice();
                              Provider.of<PortfolioProvider>(context, listen: false).saveMetadata(meta);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                            child: const Text("VALIDER", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }),

              // 1. Jamais synchronisés
              if (neverSyncedCount > 0)
                _ExpandableAlertItem(
                  icon: Icons.info_outline,
                  color: AppColors.primary,
                  title: '$neverSyncedCount actif(s) jamais synchronisé(s)',
                  subtitle: 'Lancez une synchronisation pour récupérer les prix.',
                ),

              // 2. Non synchronisables
              if (unsyncableCount > 0)
                _ExpandableAlertItem(
                  icon: Icons.block,
                  color: AppColors.textTertiary,
                  title: '$unsyncableCount actif(s) non synchronisable(s)',
                  subtitle: 'Saisissez le prix manuellement (ex: Fonds euros).',
                ),

              // 3. Erreurs
              ...assetsWithErrors.map((entry) {
                return _ExpandableAlertItem(
                  icon: Icons.error_outline,
                  color: AppColors.error,
                  title: entry.key,
                  subtitle: entry.value.syncErrorMessage ?? 'Erreur inconnue',
                  metadata: entry.value,
                  onResolve: () => _showUpdatePriceDialog(
                    context, 
                    Provider.of<PortfolioProvider>(context, listen: false), 
                    entry.key, 
                    entry.value.currentPrice
                  ),
                  onSearch: () => _searchAssetOnWeb(entry.key, entry.value.isin),
                );
              }),

              const SizedBox(height: AppDimens.paddingL),

              // Bouton d'action
              AppButton(
                label: isProcessing ? 'TRAITEMENT...' : 'TOUT RESYNCHRONISER',
                isLoading: isProcessing,
                onPressed: isProcessing
                    ? null
                    : () => Provider.of<PortfolioProvider>(context, listen: false).synchroniserLesPrix(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _searchAssetOnWeb(String ticker, String? isin) async {
    final query = Uri.encodeComponent('$ticker ${isin ?? ''} price');
    final url = Uri.parse('https://www.google.com/search?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showUpdatePriceDialog(BuildContext context, PortfolioProvider portfolio, String ticker, double? currentPrice) {
    final controller = TextEditingController(text: currentPrice?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Mettre à jour le prix', style: AppTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticker: $ticker', style: AppTypography.body),
            const SizedBox(height: AppDimens.paddingS),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Nouveau prix',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text.replaceAll(',', '.'));
              if (newPrice != null) {
                portfolio.updateAssetPrice(ticker, newPrice);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

class _ExpandableAlertItem extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final AssetMetadata? metadata;
  final VoidCallback? onResolve;
  final VoidCallback? onSearch;

  const _ExpandableAlertItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.metadata,
    this.onResolve,
    this.onSearch,
  });

  @override
  State<_ExpandableAlertItem> createState() => _ExpandableAlertItemState();
}

class _ExpandableAlertItemState extends State<_ExpandableAlertItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasDetails = widget.metadata != null &&
        (widget.metadata!.lastSyncAttempt != null ||
            (widget.metadata!.apiErrors?.isNotEmpty ?? false));

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: AppOpacities.subtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        border: Border.all(color: widget.color.withValues(alpha: AppOpacities.border)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasDetails
              ? () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }
              : null,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, color: widget.color, size: AppComponentSizes.iconMediumSmall),
                    const SizedBox(width: AppDimens.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTypography.bodyBold.copyWith(color: widget.color),
                          ),
                          AppSpacing.gapXs,
                          Text(
                            widget.subtitle,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    if (widget.onSearch != null)
                      IconButton(
                        icon: const Icon(Icons.search, size: AppComponentSizes.iconMediumSmall),
                        color: widget.color,
                        onPressed: widget.onSearch,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Rechercher',
                      ),
                    if (widget.onResolve != null) ...[
                      AppSpacing.gapH4,
                      IconButton(
                        icon: const Icon(Icons.edit, size: AppComponentSizes.iconMediumSmall),
                        color: widget.color,
                        onPressed: widget.onResolve,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Corriger',
                      ),
                    ],
                    if (hasDetails) ...[
                      AppSpacing.gapH4,
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: widget.color,
                        size: AppComponentSizes.iconMediumSmall,
                      ),
                    ],
                  ],
                ),
                if (hasDetails)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: AppDimens.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: widget.color.withValues(alpha: AppOpacities.border)),
                          if (widget.metadata!.lastSyncAttempt != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "Dernier essai : ${DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.metadata!.lastSyncAttempt!)}",
                                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (widget.metadata!.apiErrors != null && widget.metadata!.apiErrors!.isNotEmpty)
                            ...widget.metadata!.apiErrors!.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      "${e.key} :",
                                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: AppTypography.caption.copyWith(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),
                    crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}