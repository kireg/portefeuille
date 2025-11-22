// lib/core/ui/widgets/asset_list_item.dart
import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/repayment_type.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart'; // IMPORTANT
import 'package:provider/provider.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:shimmer/shimmer.dart';

class AssetListItem extends StatelessWidget {
  final Asset asset;
  final String accountCurrency;
  final String baseCurrency;

  const AssetListItem({
    super.key,
    required this.asset,
    required this.accountCurrency,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final isProcessing = provider.isProcessingInBackground;

    final totalValueConverted = provider.getConvertedAssetTotalValue(asset.id);
    final pnlConverted = provider.getConvertedAssetPL(asset.id);
    final pnlPercentage = asset.profitAndLossPercentage;
    final isPositive = pnlConverted >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Carte sombre
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)), // Bordure subtile
      ),
      child: Row(
        children: [
          // 1. Icône / Logo (Placeholder avec initiales colorées)
          _buildAssetIcon(),

          const SizedBox(width: 16),

          // 2. Nom et quantité
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (asset.type == AssetType.RealEstateCrowdfunding)
                  Text(
                    '${asset.ticker} • ${asset.expectedYield?.toStringAsFixed(1) ?? '?'}%${asset.repaymentType != null ? ' • ${asset.repaymentType!.displayName}' : ''}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  )
                else
                  Text(
                    '${CurrencyFormatter.formatQuantity(asset.quantity)} ${asset.ticker}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),

          // 3. Valeur et P&L
          if (isProcessing)
            _buildShimmer()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(totalValueConverted, baseCurrency),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${(pnlPercentage * 100).toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive ? AppColors.success : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAssetIcon() {
    // Génération d'une couleur unique basée sur le nom pour le placeholder
    final colorSeed = asset.ticker.hashCode;
    Color((0xFF000000 + (colorSeed & 0xFFFFFF))).withValues(alpha: 1.0);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        asset.ticker.substring(0, min(2, asset.ticker.length)).toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surface,
      child: Container(
        width: 80,
        height: 30,
        color: Colors.black,
      ),
    );
  }
}