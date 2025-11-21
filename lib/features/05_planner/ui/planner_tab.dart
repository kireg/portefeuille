import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Core UI
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/components/app_tile.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';

// Data & Logic
import 'package:portefeuille/core/utils/currency_formatter.dart';
import '../../00_app/providers/portfolio_provider.dart';
import '../../07_management/ui/screens/add_savings_plan_screen.dart';
import 'package:portefeuille/core/data/models/projection_data.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  int _selectedDuration = 10;
  final List<int> _durations = [5, 10, 20, 30];

  void _showDeleteConfirmation(BuildContext context, PortfolioProvider provider,
      String planId, String planName) {
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
                const SnackBar(content: Text('Plan d\'épargne supprimé')),
              );
            },
            child: Text('Supprimer', style: AppTypography.label.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _openPlanForm(BuildContext context, {SavingsPlan? existingPlan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => AddSavingsPlanScreen(existingPlan: existingPlan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        final baseCurrency = portfolioProvider.currentBaseCurrency;
        final portfolio = portfolioProvider.activePortfolio;
        final isProcessing = portfolioProvider.isProcessingInBackground;

        if (portfolio == null) {
          return const Center(child: Text("Aucun portefeuille sélectionné."));
        }

        final savingsPlans = portfolio.savingsPlans;
        final projectionData = portfolioProvider.getProjectionData(_selectedDuration);

        return AppScreen(
          withSafeArea: false,
          body: CustomScrollView(
            slivers: [
              // Titre
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingL),
                  child: Center(child: Text('Planification', style: AppTypography.h2)),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // 1. Section Plans d'Épargne
                    FadeInSlide(
                      delay: 0.1,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              'Plans d\'épargne',
                              Icons.savings_outlined,
                              onAdd: () => _openPlanForm(context),
                            ),
                            const SizedBox(height: AppDimens.paddingM),

                            if (savingsPlans.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Text('Aucun plan configuré', style: AppTypography.h3),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Créez un plan pour simuler vos investissements.',
                                        style: AppTypography.caption,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      AppButton(
                                        label: 'Créer un plan',
                                        onPressed: () => _openPlanForm(context),
                                        icon: Icons.add,
                                        isFullWidth: false,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...savingsPlans.asMap().entries.map((entry) {
                                final plan = entry.value;
                                final targetAsset = portfolioProvider.findAssetByTicker(plan.targetTicker);
                                final assetYield = targetAsset?.estimatedAnnualYield ?? 0.0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: AppTile(
                                    title: plan.name,
                                    subtitle: '${CurrencyFormatter.format(plan.monthlyAmount, baseCurrency)}/mois • ${(assetYield * 100).toStringAsFixed(1)}% /an',
                                    leading: AppIcon(
                                      icon: Icons.rocket_launch,
                                      color: plan.isActive ? AppColors.success : AppColors.textSecondary,
                                      backgroundColor: (plan.isActive ? AppColors.success : AppColors.textSecondary).withOpacity(0.1),
                                    ),
                                    onTap: () => _openPlanForm(context, existingPlan: plan),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      color: AppColors.textTertiary,
                                      onPressed: () => _showDeleteConfirmation(
                                        context, portfolioProvider, plan.id, plan.name,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimens.paddingM),

                    // 2. Section Projection
                    FadeInSlide(
                      delay: 0.2,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Projection', Icons.show_chart),
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

                              // Graphique
                              SizedBox(
                                height: 300,
                                child: Stack(
                                  children: [
                                    BarChart(_buildChartData(projectionData, baseCurrency)),
                                    if (isProcessing)
                                      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppDimens.paddingL),

                              // Légende
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildLegend('Capital actuel', AppColors.primary.withOpacity(0.5)),
                                  _buildLegend('Versements', AppColors.accent.withOpacity(0.5)),
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
                                  selected: {_selectedDuration},
                                  onSelectionChanged: (Set<int> newSelection) {
                                    setState(() => _selectedDuration = newSelection.first);
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                          (Set<WidgetState> states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return AppColors.primary.withOpacity(0.2);
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
                      ),
                    ),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AppIcon(icon: icon, size: 18, color: AppColors.primary, backgroundColor: Colors.transparent),
            const SizedBox(width: 8),
            Text(title.toUpperCase(), style: AppTypography.label.copyWith(color: AppColors.textTertiary)),
          ],
        ),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
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
    );
  }

  Widget _buildSummaryItem(String label, double value, String currency, Color color) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 4),
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
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  BarChartData _buildChartData(List<ProjectionData> data, String baseCurrency) {
    final lastData = data.last;
    final maxValue = lastData.totalValue;

    return BarChartData(
      maxY: maxValue * 1.1,
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => AppColors.surfaceLight,
          tooltipPadding: const EdgeInsets.all(12),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final d = data[groupIndex];
            return BarTooltipItem(
              'Année ${d.year}\n',
              AppTypography.caption,
              children: [
                TextSpan(
                  text: 'Total: ${CurrencyFormatter.format(d.totalValue, baseCurrency)}',
                  style: AppTypography.bodyBold.copyWith(color: AppColors.primary),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final year = value.toInt();
              // Afficher moins de labels si beaucoup d'années
              int step = _selectedDuration > 10 ? 5 : 2;
              if (year % step != 0 && year != 1 && year != _selectedDuration) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('$year', style: AppTypography.caption),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox();
              return Text(
                NumberFormat.compact().format(value),
                style: AppTypography.caption.copyWith(fontSize: 10),
                textAlign: TextAlign.right,
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(show: false), // Pas de grille
      barGroups: data.map((d) {
        return BarChartGroupData(
          x: d.year,
          barRods: [
            BarChartRodData(
              toY: d.totalValue,
              width: _selectedDuration > 20 ? 8 : 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              rodStackItems: [
                BarChartRodStackItem(0, d.currentCapital, AppColors.primary.withOpacity(0.5)),
                BarChartRodStackItem(d.currentCapital, d.currentCapital + d.cumulativeContributions, AppColors.accent.withOpacity(0.5)),
                BarChartRodStackItem(d.currentCapital + d.cumulativeContributions, d.totalValue, AppColors.success),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }
}