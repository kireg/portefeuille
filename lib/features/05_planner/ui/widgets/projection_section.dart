import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:provider/provider.dart';

import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_calculation_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

import 'projection_chart.dart';

class ProjectionSection extends StatelessWidget {
  final int selectedDuration;
  final ValueChanged<int> onDurationChanged;

  const ProjectionSection({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  final List<int> _durations = const [5, 10, 20, 30];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final calculationProvider = context.watch<PortfolioCalculationProvider>();
    final portfolioProvider = context.watch<PortfolioProvider>();

    final baseCurrency = settings.baseCurrency;
    final projectionData = calculationProvider.getProjectionData(selectedDuration);
    final isProcessing = portfolioProvider.isProcessingInBackground || calculationProvider.isCalculating;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Header
              Row(
                children: [
                  const AppIcon(
                      icon: Icons.show_chart,
                      size: AppComponentSizes.iconSmall,
                      color: AppColors.primary,
                      backgroundColor: Colors.transparent),
                  AppSpacing.gapHorizontalSmall,
                  Text('PROJECTION', style: AppTypography.label.copyWith(color: AppColors.textTertiary)),
                ],
              ),
              const SizedBox(height: AppDimens.paddingL),

              if (projectionData.isNotEmpty) ...[
                // Résumé chiffré
                Container(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Capital final',
                          projectionData.last.totalValue,
                          baseCurrency,
                          AppColors.primary,
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Expanded(
                        child: _buildSummaryItem(
                          'Gains estimés',
                          projectionData.last.cumulativeGains,
                          baseCurrency,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.paddingL),

                // Graphique Refactorisé
                SizedBox(
                  height: 300,
                  child: ProjectionChart(
                    data: projectionData,
                    baseCurrency: baseCurrency,
                    isLoading: isProcessing,
                    duration: selectedDuration,
                  ),
                ),

                const SizedBox(height: AppDimens.paddingL),

                // Légende
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildLegend('Capital actuel', AppColors.primary.withValues(alpha: AppOpacities.semiVisible)),
                    _buildLegend('Versements', AppColors.accent.withValues(alpha: AppOpacities.semiVisible)),
                    _buildLegend('Intérêts composés', AppColors.success),
                  ],
                ),

                const SizedBox(height: AppDimens.paddingL),

                // Sélecteur de durée
                Center(
                  child: SegmentedButton<int>(
                    segments: _durations.map((d) {
                      return ButtonSegment<int>(
                        value: d,
                        label: Text('$d ans', style: AppTypography.caption),
                      );
                    }).toList(),
                    selected: {selectedDuration},
                    onSelectionChanged: (Set<int> newSelection) {
                      onDurationChanged(newSelection.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary.withValues(alpha: AppOpacities.border);
                          }
                          return Colors.transparent;
                        },
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return AppColors.textSecondary;
                        },
                      ),
                    ),
                  ),
                ),
              ] else
                Center(child: Text("Pas assez de données", style: AppTypography.body)),
            ],
          ),
        );
  }

  Widget _buildSummaryItem(String label, double value, String currency, Color color) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption),
        AppSpacing.gapXs,
        Text(
          CurrencyFormatter.format(value, currency),
          style: AppTypography.bodyBold.copyWith(color: color, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppSpacing.gapH6,
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}