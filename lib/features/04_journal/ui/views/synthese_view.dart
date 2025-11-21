import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Core UI
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart'; // Si besoin de wrapper
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';

// Data & Logic
import 'package:portefeuille/core/data/models/aggregated_asset.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

class SyntheseView extends StatefulWidget {
  const SyntheseView({super.key});

  @override
  State<SyntheseView> createState() => _SyntheseViewState();
}

class _SyntheseViewState extends State<SyntheseView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final baseCurrency = provider.currentBaseCurrency;
        final aggregatedAssets = provider.aggregatedAssets;
        final isProcessing = provider.isProcessingInBackground;

        if (provider.activePortfolio == null) {
          return const Center(child: Text("Aucun portefeuille."));
        }

        if (aggregatedAssets.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingL),
                child: Text('Synthèse', style: AppTypography.h2),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  child: AppCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          icon: Icons.pie_chart_outline,
                          size: 48,
                          backgroundColor: AppColors.surfaceLight,
                        ),
                        const SizedBox(height: AppDimens.paddingM),
                        Text('Aucun actif', style: AppTypography.h3),
                        const SizedBox(height: AppDimens.paddingS),
                        Text(
                          'Ajoutez des transactions pour voir vos actifs ici.',
                          style: AppTypography.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingL),
                    child: Center(child: Text('Synthèse', style: AppTypography.h2)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.paddingM,
                      0,
                      AppDimens.paddingM,
                      80 // Espace pour le bas
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final asset = aggregatedAssets[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                          child: FadeInSlide(
                            delay: index * 0.05,
                            child: _AssetCard(
                              asset: asset,
                              baseCurrency: baseCurrency,
                              onEditPrice: () => _showEditPriceDialog(
                                  context, asset, provider, asset.assetCurrency
                              ),
                              onEditYield: () => _showEditYieldDialog(
                                  context, asset, provider
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: aggregatedAssets.length,
                    ),
                  ),
                ),
              ],
            ),

            // Overlay de chargement si nécessaire
            if (isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppDimens.paddingL),
                      backgroundColor: AppColors.surface,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: AppDimens.paddingM),
                          Text('Calcul en cours...', style: AppTypography.bodyBold),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // --- Dialogs d'édition (Code logique conservé, style adapté minimalement) ---

  void _showEditYieldDialog(
      BuildContext context, AggregatedAsset asset, PortfolioProvider provider) {
    final controller = TextEditingController(
        text: (asset.estimatedAnnualYield * 100).toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Modifier rendement', style: AppTypography.h3),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTypography.body,
          decoration: InputDecoration(
            labelText: 'Rendement annuel (%)',
            labelStyle: AppTypography.caption,
            suffixText: '%',
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textTertiary)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuler', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final enteredValue =
                  double.tryParse(controller.text.replaceAll(',', '.')) ??
                      (asset.estimatedAnnualYield * 100);
              final newYieldAsDecimal = enteredValue / 100.0;
              provider.updateAssetYield(asset.ticker, newYieldAsDecimal);
              Navigator.of(ctx).pop();
            },
            child: Text('Sauvegarder', style: AppTypography.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, AggregatedAsset asset,
      PortfolioProvider provider, String nativeCurrency) {
    final nativePrice = asset.metadata?.currentPrice ?? asset.currentPrice;
    final controller = TextEditingController(text: nativePrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Modifier prix', style: AppTypography.h3),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTypography.body,
          decoration: InputDecoration(
            labelText: 'Prix actuel ($nativeCurrency)',
            labelStyle: AppTypography.caption,
            suffixText: nativeCurrency,
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textTertiary)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuler', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final newPrice =
                  double.tryParse(controller.text.replaceAll(',', '.')) ??
                      nativePrice;
              provider.updateAssetPrice(asset.ticker, newPrice,
                  currency: nativeCurrency);
              Navigator.of(ctx).pop();
            },
            child: Text('Sauvegarder', style: AppTypography.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// --- Widget Carte d'Actif ---

class _AssetCard extends StatelessWidget {
  final AggregatedAsset asset;
  final String baseCurrency;
  final VoidCallback onEditPrice;
  final VoidCallback onEditYield;

  const _AssetCard({
    required this.asset,
    required this.baseCurrency,
    required this.onEditPrice,
    required this.onEditYield,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = asset.profitAndLoss >= 0;
    final pnlColor = isPositive ? AppColors.success : AppColors.error;

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Column(
        children: [
          // 1. En-tête (Icône + Nom + Statut)
          Row(
            children: [
              _buildAssetIcon(),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.name, style: AppTypography.bodyBold, overflow: TextOverflow.ellipsis),
                    Text(asset.ticker, style: AppTypography.caption),
                  ],
                ),
              ),
              _buildSyncStatusBadge(asset.syncStatus),
            ],
          ),

          const SizedBox(height: AppDimens.paddingM),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimens.paddingM),

          // 2. Grille d'infos
          Row(
            children: [
              // Colonne Gauche : Quantité & PRU
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoLabel('Quantité'),
                    Text(asset.quantity.toStringAsFixed(2), style: AppTypography.body),
                    const SizedBox(height: AppDimens.paddingS),
                    _buildInfoLabel('PRU'),
                    Text(
                      CurrencyFormatter.format(asset.averagePrice, baseCurrency),
                      style: AppTypography.body,
                    ),
                  ],
                ),
              ),
              // Colonne Droite : Prix Actuel & Valeur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildInfoLabel('Prix Actuel'),
                    GestureDetector(
                      onTap: onEditPrice,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CurrencyFormatter.format(asset.currentPrice, baseCurrency),
                            style: AppTypography.body.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    _buildInfoLabel('Valeur Totale'),
                    Text(
                      CurrencyFormatter.format(asset.totalValue, baseCurrency),
                      style: AppTypography.bodyBold,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.paddingM),

          // 3. Pied de page : P/L & Rendement
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingS),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // P/L
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: pnlColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${CurrencyFormatter.format(asset.profitAndLoss, baseCurrency)}',
                      style: AppTypography.bodyBold.copyWith(color: pnlColor, fontSize: 13),
                    ),
                  ],
                ),
                // Rendement
                GestureDetector(
                  onTap: onEditYield,
                  child: Row(
                    children: [
                      Text(
                        'Rendement: ${(asset.estimatedAnnualYield * 100).toStringAsFixed(1)}%',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 12, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
    );
  }

  Widget _buildAssetIcon() {
    final colorSeed = asset.ticker.hashCode;
    // Génère une couleur unique mais cohérente pour chaque ticker
    final color = Color((0xFF000000 + (colorSeed & 0xFFFFFF))).withOpacity(1.0);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        asset.ticker.substring(0, asset.ticker.length > 2 ? 2 : asset.ticker.length).toUpperCase(),
        style: AppTypography.bodyBold.copyWith(color: color),
      ),
    );
  }

  Widget _buildSyncStatusBadge(SyncStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case SyncStatus.synced:
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case SyncStatus.error:
        color = AppColors.error;
        icon = Icons.error;
        break;
      case SyncStatus.manual:
        color = AppColors.primary;
        icon = Icons.edit;
        break;
      case SyncStatus.never:
      case SyncStatus.unsyncable:
        color = AppColors.textTertiary;
        icon = Icons.circle_outlined;
        break;
    }

    return Tooltip(
      message: status.name, // Ou un message plus complet
      child: Icon(icon, color: color, size: 18),
    );
  }
}