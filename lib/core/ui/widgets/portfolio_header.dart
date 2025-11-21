import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_animated_value.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

class PortfolioHeader extends StatelessWidget {
  const PortfolioHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final baseCurrency = provider.currentBaseCurrency;
    final isProcessing = provider.isProcessingInBackground;

    final totalValue = provider.activePortfolioTotalValue;
    final totalPL = provider.activePortfolioTotalPL;
    final totalPLPercentage = provider.activePortfolioTotalPLPercentage;
    final isPositive = totalPL >= 0;

    return AppCard(
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: Column(
        // ▼▼▼ MODIFICATION : Centrage Horizontal ▼▼▼
        crossAxisAlignment: CrossAxisAlignment.center,
        // ▲▲▲ FIN MODIFICATION ▲▲▲
        children: [
          Text(
            'Solde total'.toUpperCase(),
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppDimens.paddingS),

          if (isProcessing)
            _buildShimmer()
          else
            AppAnimatedValue(
              value: totalValue,
              currency: baseCurrency,
              style: AppTypography.hero.copyWith(
                fontSize: 36,
              ),
            ),

          const SizedBox(height: AppDimens.paddingM),

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingM,
                vertical: AppDimens.paddingS
            ),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
              border: Border.all(
                color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? AppColors.success : AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${isPositive ? '+' : ''}${CurrencyFormatter.format(totalPL, baseCurrency)}',
                  style: AppTypography.bodyBold.copyWith(
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  '  (${NumberFormat.percentPattern().format(totalPLPercentage)})',
                  style: AppTypography.body.copyWith(
                    color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surface,
      child: Container(
        width: 200,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
      ),
    );
  }
}