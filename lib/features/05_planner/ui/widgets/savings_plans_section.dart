import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/components/app_tile.dart';
import 'package:portefeuille/core/ui/widgets/empty_states/app_empty_state.dart';

import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_savings_plan_screen.dart';

class SavingsPlansSection extends StatelessWidget {
  const SavingsPlansSection({super.key});

  void _openPlanForm(BuildContext context, {dynamic existingPlan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => AddSavingsPlanScreen(existingPlan: existingPlan),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, PortfolioProvider provider, String planId, String planName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Supprimer ?', style: AppTypography.h3),
        content: Text(
          'Voulez-vous vraiment supprimer le plan "$planName" ?',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuler', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSavingsPlan(planId);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Plan d\'épargne supprimé'),
                  showCloseIcon: true,
                ),
              );
            },
            child: Text('Supprimer', style: AppTypography.label.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final provider = context.watch<PortfolioProvider>();
    
    final portfolio = provider.activePortfolio;
    if (portfolio == null) return const SizedBox();

    final savingsPlans = portfolio.savingsPlans;
    final baseCurrency = settings.baseCurrency;

    if (savingsPlans.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          title: 'Aucun plan d\'épargne',
          message: 'Programmez vos versements réguliers pour simuler votre patrimoine futur.',
          icon: Icons.savings_outlined,
          buttonLabel: 'Créer un plan',
          onAction: () => _openPlanForm(context),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AppIcon(
                          icon: Icons.savings_outlined,
                          size: 18,
                          color: AppColors.primary,
                          backgroundColor: Colors.transparent),
                      const SizedBox(width: 8),
                      Text('PLANS D\'ÉPARGNE',
                          style: AppTypography.label.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _openPlanForm(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.add, size: 16, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.paddingM),

              // Liste ou Empty State
              ...savingsPlans.map((plan) {
                  final targetAsset = provider.findAssetByTicker(plan.targetTicker);
                  final assetYield = targetAsset?.estimatedAnnualYield ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: AppTile(
                      title: plan.name,
                      subtitle:
                      '${CurrencyFormatter.format(plan.monthlyAmount, baseCurrency)}/mois • ${(assetYield * 100).toStringAsFixed(1)}% /an',
                      leading: AppIcon(
                        icon: Icons.rocket_launch,
                        color: plan.isActive ? AppColors.success : AppColors.textSecondary,
                        backgroundColor: (plan.isActive ? AppColors.success : AppColors.textSecondary)
                            .withValues(alpha: 0.1),
                      ),
                      onTap: () => _openPlanForm(context, existingPlan: plan),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.textTertiary,
                        onPressed: () => _showDeleteConfirmation(
                          context, provider, plan.id, plan.name,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
  }
}