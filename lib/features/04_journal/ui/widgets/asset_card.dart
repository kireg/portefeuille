// lib/features/04_summary/ui/widgets/asset_card.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/core/data/models/aggregated_asset.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';

class AssetCard extends StatelessWidget {
  final AggregatedAsset asset;
  final String baseCurrency;
  final VoidCallback onEditPrice;
  final VoidCallback onEditYield;

  const AssetCard({
    super.key,
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
          // 1. En-tête
          Row(
            children: [
              _buildAssetIcon(),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.name,
                        style: AppTypography.bodyBold,
                        overflow: TextOverflow.ellipsis),
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
              // Gauche : Quantité & PRU
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoLabel('Quantité'),
                    Text(CurrencyFormatter.formatQuantity(asset.quantity),
                        style: AppTypography.body),
                    const SizedBox(height: AppDimens.paddingS),
                    _buildInfoLabel('PRU'),
                    Text(
                      CurrencyFormatter.format(asset.averagePrice, baseCurrency),
                      style: AppTypography.body,
                    ),
                  ],
                ),
              ),
              // Droite : Prix Actuel & Valeur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildInfoLabel('Prix Actuel'),
                    // --- MODIFICATION ICI : InkWell pour effet visuel ---
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onEditPrice,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                CurrencyFormatter.format(asset.currentPrice, baseCurrency),
                                style: AppTypography.body
                                    .copyWith(color: AppColors.primary),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 12, color: AppColors.primary),
                            ],
                          ),
                        ),
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
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingS, vertical: 4), // Padding vertical réduit pour laisser place au InkWell
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Partie P/L (Non cliquable)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: pnlColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${CurrencyFormatter.format(asset.profitAndLoss, baseCurrency)}',
                        style: AppTypography.bodyBold
                            .copyWith(color: pnlColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // --- MODIFICATION ICI : InkWell pour le rendement ---
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEditYield,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0), // Zone de clic confortable
                      child: Row(
                        children: [
                          Text(
                            'Rendement: ${(asset.estimatedAnnualYield * 100).toStringAsFixed(1)}%',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit,
                              size: 12, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
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
        asset.ticker
            .substring(0, asset.ticker.length > 2 ? 2 : asset.ticker.length)
            .toUpperCase(),
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
      message: status.name,
      child: Icon(icon, color: color, size: 18),
    );
  }
}