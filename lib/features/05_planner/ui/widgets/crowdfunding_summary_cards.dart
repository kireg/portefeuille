import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';

class CrowdfundingSummaryCards extends StatelessWidget {
  final List<Asset> assets;

  const CrowdfundingSummaryCards({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
    final crowdfundingAssets = assets.where((a) => a.type == AssetType.RealEstateCrowdfunding).toList();

    if (crowdfundingAssets.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalInvested = 0.0;
    double totalCurrentValue = 0.0;
    double weightedYieldSum = 0.0;

    for (final asset in crowdfundingAssets) {
      totalInvested += asset.totalInvestedCapital;
      totalCurrentValue += asset.totalValue;
      weightedYieldSum += (asset.totalInvestedCapital * (asset.expectedYield ?? 0.0));
    }

    final totalInterests = totalCurrentValue - totalInvested;
    final averageYield = totalInvested > 0 ? weightedYieldSum / totalInvested : 0.0;

    final currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
            child: Text("Synthèse Crowdfunding", style: AppTypography.h3),
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 117, // Hauteur fixe pour alignement
                  child: _buildSummaryCard(
                    context,
                    title: "Capital Investi",
                    value: currencyFormat.format(totalInvested),
                    icon: Icons.account_balance_wallet,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: SizedBox(
                  height: 117, // Hauteur fixe pour alignement
                  child: _buildSummaryCard(
                    context,
                    title: "Valeur Actuelle",
                    value: currencyFormat.format(totalCurrentValue),
                    subtitle: "+${currencyFormat.format(totalInterests)} (Intérêts)",
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 117, // Hauteur fixe pour alignement
                  child: _buildSummaryCard(
                    context,
                    title: "Rendement Moyen",
                    value: "${averageYield.toStringAsFixed(1)}%",
                    icon: Icons.percent,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: SizedBox(
                  height: 117, // Hauteur fixe pour alignement
                  child: _buildSummaryCard(
                    context,
                    title: "Projets Actifs",
                    value: crowdfundingAssets.length.toString(),
                    icon: Icons.apartment,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h2.copyWith(fontSize: 20),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(color: AppColors.success),
            ),
          ],
        ],
      ),
    );
  }
}
