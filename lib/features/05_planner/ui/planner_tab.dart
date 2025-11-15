import 'dart:math';
import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import '../../../core/data/models/asset.dart';
import '../../00_app/providers/portfolio_provider.dart';
import '../../07_management/ui/screens/add_savings_plan_screen.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

class ProjectionData {
  final int year;
  final double initialInvestedCapital;
  final double currentPortfolioValue;
  final double newInvestments;
  final double totalValue;

  ProjectionData({
    required this.year,
    required this.initialInvestedCapital,
    required this.currentPortfolioValue,
    required this.newInvestments,
    required this.totalValue,
  });

  double get investedCapital => initialInvestedCapital + newInvestments;
  double get totalGain => totalValue - investedCapital;
  double get realizedGains => currentPortfolioValue - initialInvestedCapital;
  double get projectedGains => totalValue - currentPortfolioValue - newInvestments;
}

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  int _selectedDuration = 10;
  final List<int> _durations = [5, 10, 20, 30];

  Asset? _findAssetByTicker(portfolio, String ticker) {
    for (var institution in portfolio.institutions) {
      for (var account in institution.accounts) {
        for (var asset in account.assets) {
          if (asset.ticker == ticker) return asset;
        }
      }
    }
    return null;
  }

  void _showDeleteConfirmation(BuildContext context, PortfolioProvider provider,
      String planId, String planName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le plan'),
        content: Text('Voulez-vous vraiment supprimer le plan "$planName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSavingsPlan(planId);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan d\'épargne supprimé')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _openPlanForm(BuildContext context, {existingPlan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddSavingsPlanScreen(existingPlan: existingPlan),
    );
  }

  List<ProjectionData> _generateProjectionData(Portfolio portfolio) {
    List<ProjectionData> data = [];
    final double initialPortfolioValue = portfolio.totalValue;
    final double initialInvestedCapital = portfolio.totalInvestedCapital;
    final double portfolioAnnualYield = portfolio.estimatedAnnualYield;

    double totalMonthlyInvestment = 0;
    double weightedPlansYield = 0;

    for (var plan in portfolio.savingsPlans.where((p) => p.isActive)) {
      final targetAsset = _findAssetByTicker(portfolio, plan.targetTicker);
      final assetYield = (targetAsset?.estimatedAnnualYield ?? 0.0);
      totalMonthlyInvestment += plan.monthlyAmount;
      weightedPlansYield += plan.monthlyAmount * assetYield;
    }

    final double averagePlansYield = (totalMonthlyInvestment > 0)
        ? weightedPlansYield / totalMonthlyInvestment
        : 0.0;

    for (int year = 1; year <= _selectedDuration; year++) {
      final double futureBaseValue =
          initialPortfolioValue * pow(1 + portfolioAnnualYield, year);
      final double futureSavingsValue = SavingsPlan(
        id: '',
        name: '',
        monthlyAmount: totalMonthlyInvestment,
        targetTicker: '',
      ).futureValue(year, averagePlansYield);
      final double newInvestments = totalMonthlyInvestment * 12 * year;
      final double totalValue = futureBaseValue + futureSavingsValue;

      data.add(ProjectionData(
        year: year,
        initialInvestedCapital: initialInvestedCapital,
        currentPortfolioValue: initialPortfolioValue,
        newInvestments: newInvestments,
        totalValue: totalValue,
      ));
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        final portfolio = portfolioProvider.activePortfolio;

        if (portfolio == null) {
          return const Center(child: Text("Aucun portefeuille sélectionné."));
        }

        final savingsPlans = portfolio.savingsPlans;
        final projectionData = _generateProjectionData(portfolio);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppTheme.buildScreenTitle(
                context: context,
                title: 'Planification',
                centered: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Section Plans d'Épargne
                  AppTheme.buildStyledCard(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTheme.buildSectionHeader(
                          context: context,
                          icon: Icons.savings_outlined,
                          title: 'Plans d\'Épargne Mensuels',
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            tooltip: 'Ajouter un plan d\'épargne',
                            onPressed: () => _openPlanForm(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (savingsPlans.isEmpty)
                          AppTheme.buildInfoContainer(
                            context: context,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.savings_outlined,
                                        size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Aucun plan d\'épargne configuré',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Créez un plan pour simuler vos investissements futurs',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => _openPlanForm(context),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Créer un plan'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ...savingsPlans.asMap().entries.map((entry) {
                            final index = entry.key;
                            final plan = entry.value;
                            final targetAsset =
                            _findAssetByTicker(portfolio, plan.targetTicker);
                            final assetName = targetAsset?.name ?? 'Actif inconnu';
                            final assetYield =
                                targetAsset?.estimatedAnnualYield ?? 0.0;

                            return Column(
                              children: [
                                if (index > 0) const SizedBox(height: 12),
                                AppTheme.buildInfoContainer(
                                  context: context,
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.add_shopping_cart,
                                      color: plan.isActive
                                          ? theme.colorScheme.primary
                                          : Colors.grey,
                                    ),
                                    title: Text(
                                      plan.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cible : $assetName (${plan.targetTicker})',
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '${plan.monthlyAmount.toStringAsFixed(0)} €/mois',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '• ${(assetYield * 100).toStringAsFixed(1)}% /an',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined,
                                                  size: 20,
                                                  color: Colors.grey.shade700),
                                              const SizedBox(width: 8),
                                              const Text('Modifier'),
                                            ],
                                          ),
                                          onTap: () {
                                            Future.delayed(
                                                const Duration(milliseconds: 100),
                                                    () {
                                                  _openPlanForm(context,
                                                      existingPlan: plan);
                                                });
                                          },
                                        ),
                                        PopupMenuItem(
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline,
                                                  size: 20,
                                                  color: Colors.red.shade700),
                                              const SizedBox(width: 8),
                                              const Text('Supprimer',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ],
                                          ),
                                          onTap: () {
                                            Future.delayed(
                                                const Duration(milliseconds: 100),
                                                    () {
                                                  _showDeleteConfirmation(
                                                    context,
                                                    portfolioProvider,
                                                    plan.id,
                                                    plan.name,
                                                  );
                                                });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Section Projection
                  AppTheme.buildStyledCard(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTheme.buildSectionHeader(
                          context: context,
                          icon: Icons.trending_up,
                          title: 'Projection ($_selectedDuration ans)',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: projectionData.isEmpty
                              ? const Center(
                              child: Text('Aucune donnée à projeter.'))
                              : BarChart(_buildChartData(projectionData, theme)),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            AppTheme.buildLegendItem(
                              color: theme.colorScheme.primary.withOpacity(0.6),
                              label: 'Capital investi',
                              theme: theme,
                            ),
                            AppTheme.buildLegendItem(
                              color: Colors.green.shade200,
                              label: 'Gains réalisés',
                              theme: theme,
                            ),
                            AppTheme.buildLegendItem(
                              color: Colors.green.shade600,
                              label: 'Gains projetés',
                              theme: theme,
                            ),
                            AppTheme.buildLegendItem(
                              color: theme.colorScheme.secondary.withOpacity(0.8),
                              label: 'Nouveaux versements',
                              theme: theme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ToggleButtons(
                            isSelected: _durations
                                .map((d) => d == _selectedDuration)
                                .toList(),
                            onPressed: (index) {
                              setState(() {
                                _selectedDuration = _durations[index];
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            constraints: const BoxConstraints(
                                minHeight: 40, minWidth: 60),
                            children: _durations.map((d) => Text('$d ans')).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  BarChartData _buildChartData(List<ProjectionData> data, ThemeData theme) {
    final lastData = data.last;
    final maxValue = lastData.totalValue;
    final interval = maxValue > 0 ? maxValue / 5 : 1.0;

    final barGroups = data.map((d) {
      return BarChartGroupData(
        x: d.year,
        barRods: [
          BarChartRodData(
            toY: d.totalValue,
            borderRadius: BorderRadius.zero,
            width: 18,
            rodStackItems: d.year == 1
                ? [
              BarChartRodStackItem(
                0,
                d.initialInvestedCapital,
                theme.colorScheme.primary.withOpacity(0.6),
              ),
              BarChartRodStackItem(
                d.initialInvestedCapital,
                d.currentPortfolioValue,
                Colors.green.shade200,
              ),
              if (d.newInvestments > 0)
                BarChartRodStackItem(
                  d.currentPortfolioValue,
                  d.currentPortfolioValue + d.newInvestments,
                  theme.colorScheme.secondary.withOpacity(0.8),
                ),
              BarChartRodStackItem(
                d.currentPortfolioValue + d.newInvestments,
                d.totalValue,
                Colors.green.shade600,
              ),
            ]
                : [
              BarChartRodStackItem(
                0,
                d.initialInvestedCapital,
                theme.colorScheme.primary.withOpacity(0.6),
              ),
              BarChartRodStackItem(
                d.initialInvestedCapital,
                d.investedCapital,
                theme.colorScheme.secondary.withOpacity(0.8),
              ),
              BarChartRodStackItem(
                d.investedCapital,
                d.totalValue,
                Colors.green.shade400,
              ),
            ],
          ),
        ],
      );
    }).toList();

    return BarChartData(
      maxY: maxValue * 1.1,
      barGroups: barGroups,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              if (value == 0 || value > maxValue) return const SizedBox();

              String text;
              if (value > 1000000) {
                text = '${(value / 1000000).toStringAsFixed(1)}M';
              } else if (value > 1000) {
                text = '${(value / 1000).toStringAsFixed(0)}K';
              } else {
                text = value.toStringAsFixed(0);
              }

              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final year = value.toInt();

              if (year % (_selectedDuration > 10 ? 2 : 1) != 0 &&
                  year != 1 &&
                  year != _selectedDuration) {
                return const SizedBox();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  year.toString(),
                  style: theme.textTheme.bodySmall,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.1),
          strokeWidth: 1,
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final d = data[groupIndex];
            if (d.year == 1) {
              return BarTooltipItem(
                'Année ${d.year}\n'
                    'Total: ${CurrencyFormatter.format(d.totalValue)}\n'
                    'Investi: ${CurrencyFormatter.format(d.investedCapital)}\n'
                    'Gains réalisés: ${CurrencyFormatter.format(d.realizedGains)}\n'
                    'Gains projetés: ${CurrencyFormatter.format(d.projectedGains)}',
                theme.textTheme.bodySmall!.copyWith(color: Colors.white),
              );
            }
            return BarTooltipItem(
              'Année ${d.year}\n'
                  'Total: ${CurrencyFormatter.format(d.totalValue)}\n'
                  'Investi: ${CurrencyFormatter.format(d.investedCapital)}\n'
                  'Gains: ${CurrencyFormatter.format(d.totalGain)}',
              theme.textTheme.bodySmall!.copyWith(color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}