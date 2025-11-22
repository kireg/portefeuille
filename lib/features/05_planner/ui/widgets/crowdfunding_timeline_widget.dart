import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';

class CrowdfundingTimelineWidget extends StatelessWidget {
  final List<Asset> assets;

  const CrowdfundingTimelineWidget({
    super.key,
    required this.assets,
  });

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();

    // Trier par date de fin estimée
    final sortedAssets = List<Asset>.from(assets);
    sortedAssets.sort((a, b) {
      final endA = _getEndDate(a);
      final endB = _getEndDate(b);
      return endA.compareTo(endB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
          child: Text(
            "Calendrier des Projets",
            style: AppTypography.h3,
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          itemCount: sortedAssets.length,
          itemBuilder: (context, index) {
            final asset = sortedAssets[index];
            final endDate = _getEndDate(asset);
            final isLast = index == sortedAssets.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne Date
                  SizedBox(
                    width: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('MMM', 'fr_FR').format(endDate).toUpperCase(),
                          style: AppTypography.bodyBold.copyWith(color: AppColors.primary),
                        ),
                        Text(
                          DateFormat('yyyy', 'fr_FR').format(endDate),
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  // Ligne Timeline
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.surfaceLight,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  // Carte Projet
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                      child: _buildAssetCard(asset),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAssetCard(Asset asset) {
    final startDate = _getStartDate(asset);
    final endDate = _getEndDate(asset);
    final now = DateTime.now();
    final totalDuration = endDate.difference(startDate).inDays;
    final elapsed = now.difference(startDate).inDays;
    final progress = (totalDuration > 0) ? (elapsed / totalDuration).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            asset.name,
            style: AppTypography.bodyBold,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                endDate.isBefore(now) ? AppColors.error : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(progress * 100).toInt()}%",
                style: AppTypography.caption,
              ),
              if (endDate.isBefore(now))
                Text("Terminé", style: AppTypography.caption.copyWith(color: AppColors.success))
              else
                Text("${endDate.difference(now).inDays} jours", style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _getStartDate(Asset asset) {
    if (asset.transactions.isEmpty) return DateTime.now();
    final buyTransactions = asset.transactions
        .where((t) => t.type == TransactionType.Buy)
        .toList();
    if (buyTransactions.isEmpty) return DateTime.now();
    buyTransactions.sort((a, b) => a.date.compareTo(b.date));
    return buyTransactions.first.date;
  }

  DateTime _getEndDate(Asset asset) {
    final start = _getStartDate(asset);
    final duration = asset.targetDuration ?? 0;
    return start.add(Duration(days: duration * 30));
  }
}
