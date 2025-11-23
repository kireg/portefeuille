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
import 'package:portefeuille/features/00_app/providers/portfolio_calculation_provider.dart';

class PortfolioHeader extends StatelessWidget {
  const PortfolioHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final calculationProvider = context.watch<PortfolioCalculationProvider>();
    
    final baseCurrency = calculationProvider.currentBaseCurrency;
    final isProcessing = provider.isProcessingInBackground || calculationProvider.isCalculating;

    final totalValue = calculationProvider.activePortfolioTotalValue;
    final totalPL = calculationProvider.activePortfolioTotalPL;
    final totalPLPercentage = calculationProvider.activePortfolioTotalPLPercentage;
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

          const SizedBox(height: AppDimens.paddingL),

          // --- GRILLE DE SYNTHÈSE (4 CARDS) ---
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      label: 'Capital Investi',
                      value: calculationProvider.activePortfolioTotalInvested,
                      currency: baseCurrency,
                      color: AppColors.primary,
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      label: 'Intérêts Latents',
                      value: totalPL,
                      currency: baseCurrency,
                      color: isPositive ? AppColors.success : AppColors.error,
                      icon: isPositive ? Icons.trending_up : Icons.trending_down,
                      showSign: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.paddingM),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      label: 'Liquidités',
                      value: calculationProvider.activePortfolioCashValue,
                      currency: baseCurrency,
                      color: Colors.orange,
                      icon: Icons.savings,
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      label: 'Performance',
                      value: totalPLPercentage,
                      currency: null, // Pourcentage
                      isPercentage: true,
                      color: isPositive ? AppColors.success : AppColors.error,
                      icon: Icons.percent,
                      showSign: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String label,
    required double value,
    String? currency,
    required Color color,
    required IconData icon,
    bool isPercentage = false,
    bool showSign = false,
  }) {
    final formattedValue = isPercentage
        ? NumberFormat.percentPattern().format(value)
        : CurrencyFormatter.format(value, currency ?? 'EUR');
    
    final displayValue = (showSign && value > 0 && !isPercentage) 
        ? '+$formattedValue' 
        : formattedValue;

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayValue,
            style: AppTypography.h3.copyWith(
              color: color,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
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