// lib/features/04_summary/ui/widgets/asset_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_elevations.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/core/data/models/aggregated_asset.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:url_launcher/url_launcher.dart';

class AssetCard extends StatefulWidget {
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
  State<AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<AssetCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.asset.profitAndLoss >= 0;
    final pnlColor = isPositive ? AppColors.success : AppColors.error;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.6), // Transparence
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: AppElevations.sm,
          ),
          child: Column(
            children: [
              // HEADER (Toujours visible)
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: AppSpacing.assetCardHeaderPaddingDefault,
                  child: Row(
                    children: [
                      _buildAssetIcon(),
                      AppSpacing.gapM,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.asset.name,
                                style: AppTypography.bodyBold,
                                overflow: TextOverflow.ellipsis),
                            Text(widget.asset.ticker, style: AppTypography.caption),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(widget.asset.totalValue, widget.baseCurrency),
                            style: AppTypography.bodyBold,
                          ),
                          Text(
                            "${isPositive ? '+' : ''}${CurrencyFormatter.format(widget.asset.profitAndLoss, widget.baseCurrency)}",
                            style: AppTypography.caption.copyWith(color: pnlColor),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppDimens.paddingS),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              // BODY (Expandable)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Column(
                        children: [
                          // Ligne 1 : Quantité & PRU
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  "Quantité",
                                  CurrencyFormatter.formatQuantity(widget.asset.quantity),
                                ),
                              ),
                              Expanded(
                                child: _buildDetailRow(
                                  "PRU",
                                  CurrencyFormatter.format(widget.asset.averagePrice, widget.baseCurrency),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.paddingM),
                          // Ligne 2 : Prix Actuel & Rendement
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoLabel('Prix Actuel'),
                                    InkWell(
                                      onTap: widget.onEditPrice,
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              CurrencyFormatter.format(widget.asset.currentPrice, widget.baseCurrency),
                                              style: AppTypography.body.copyWith(color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.edit, size: 14, color: AppColors.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoLabel('Rendement Est.'),
                                    InkWell(
                                      onTap: widget.onEditYield,
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "${(widget.asset.estimatedAnnualYield * 100).toStringAsFixed(2)}%",
                                              style: AppTypography.body.copyWith(color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.edit, size: 14, color: AppColors.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.paddingM),
                          // Sync Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoLabel("Statut Synchro"),
                              _buildSyncStatusBadge(widget.asset.syncStatus),
                            ],
                          ),
                          const SizedBox(height: AppDimens.paddingM),
                          // Accounts
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoLabel("Comptes"),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.end,
                                  children: widget.asset.accountNames.map((name) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(name, style: AppTypography.caption),
                                  )).toList(),
                                ),
                              ),
                            ],
                          ),
                          
                          // Search Ticker (if needed)
                          if (widget.asset.syncStatus != SyncStatus.synced)
                            Padding(
                              padding: const EdgeInsets.only(top: AppDimens.paddingM),
                              child: InkWell(
                                onTap: () async {
                                  final url = Uri.parse("https://finance.yahoo.com/lookup?s=${widget.asset.ticker}");
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.search, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text("Rechercher le ticker (Yahoo)", style: AppTypography.caption.copyWith(color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoLabel(label),
        Text(value, style: AppTypography.body),
      ],
    );
  }

  Widget _buildInfoLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.caption.copyWith(
        fontSize: 10,
        letterSpacing: 1.0,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildAssetIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          widget.asset.ticker.isNotEmpty ? widget.asset.ticker[0] : '?',
          style: AppTypography.h3.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildSyncStatusBadge(SyncStatus status) {
    Color color;
    String text;

    switch (status) {
      case SyncStatus.synced:
        color = AppColors.success;
        text = 'SYNC';
        break;
      case SyncStatus.error:
        color = AppColors.error;
        text = 'ERROR';
        break;
      case SyncStatus.manual:
        color = AppColors.textSecondary;
        text = 'MANUEL';
        break;
      case SyncStatus.never:
        color = AppColors.textTertiary;
        text = 'JAMAIS';
        break;
      default:
        color = AppColors.textTertiary;
        text = 'INCONNU';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}