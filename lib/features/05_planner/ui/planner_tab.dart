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

// NOUVEAU : Classe pour les données de projection
class ProjectionData {
  final int year;
  final double baseValue; // Valeur du portefeuille initial
  final double investedCapital; // Total des apports (plans)
  final double totalValue; // Valeur totale projetée (base + apports + intérêts)

  ProjectionData({
    required this.year,
    required this.baseValue,
    required this.investedCapital,
    required this.totalValue,
  });

  // Gain total (hors capital initial)
  double get totalGain => totalValue - baseValue - investedCapital;
}

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  // NOUVEAU : État pour la durée de projection
  int _selectedDuration = 10; // Durée par défaut (10 ans)
  final List<int> _durations = [5, 10, 20, 30];

  /// Trouve un actif dans le portefeuille par son ticker
  Asset?
  _findAssetByTicker(portfolio, String ticker) {
    for (var institution in portfolio.institutions) {
      for (var account in institution.accounts) {
        for (var asset in account.assets) {
          if (asset.ticker == ticker) {
            return asset;
          }
        }
      }
    }
    return null;
  }

  /// Affiche le dialogue de confirmation de suppression
  void _showDeleteConfirmation(BuildContext context, PortfolioProvider provider, String planId, String planName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le plan'),
        content: Text('Voulez-vous vraiment supprimer le plan "$planName" ?'),
        actions: [
          TextButton(
            onPressed: ()
            => Navigator.of(context).pop(),
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

  /// Ouvre le formulaire d'ajout ou de modification
  void _openPlanForm(BuildContext context, {existingPlan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddSavingsPlanScreen(existingPlan: existingPlan),
    );
  }

  // NOUVEAU : Logique de génération des données pour le graphique
  List<ProjectionData> _generateProjectionData(Portfolio portfolio) {
    List<ProjectionData> data = [];
    final double initialPortfolioValue = portfolio.totalValue;
    final double portfolioAnnualYield = portfolio.estimatedAnnualYield / 100.0;

    // Calculer le total des versements mensuels et le rendement pondéré des plans
    double totalMonthlyInvestment = 0;
    double weightedPlansYield = 0;

    for (var plan in portfolio.savingsPlans.where((p) => p.isActive)) {
      final targetAsset = _findAssetByTicker(portfolio, plan.targetTicker);
      final assetYield = (targetAsset?.estimatedAnnualYield ?? 0.0) / 100.0;

      totalMonthlyInvestment += plan.monthlyAmount;
      weightedPlansYield += plan.monthlyAmount * assetYield;
    }

    final double averagePlansYield = (totalMonthlyInvestment > 0)
        ? weightedPlansYield / totalMonthlyInvestment
        : 0.0;

    // Simuler année par année
    for (int year = 1; year <= _selectedDuration; year++) {
      // 1. Valeur future du portefeuille initial (intérêts composés)
      final double futureBaseValue =
          initialPortfolioValue * pow(1 + portfolioAnnualYield, year);

      // 2. Valeur future des plans d'épargne (formule d'annuité)
      final double futureSavingsValue = SavingsPlan(
        id: '',
        name: '',
        monthlyAmount: totalMonthlyInvestment,
        targetTicker: '',
      ).futureValue(year, averagePlansYield);

      final double totalCapitalInvested = totalMonthlyInvestment * 12 * year;
      final double totalValue = futureBaseValue + futureSavingsValue;

      data.add(ProjectionData(
        year: year,
        baseValue: futureBaseValue,
        investedCapital: totalCapitalInvested,
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
        // NOUVEAU : Générer les données
        final projectionData = _generateProjectionData(portfolio);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre avec bouton d'ajout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Expanded(
                    child: Text(
                      'Plans d\'Épargne Mensuels',
                      style: theme.textTheme.titleLarge,
                    ),

                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color:
                      theme.colorScheme.primary,
                    ),
                    tooltip: 'Ajouter un plan d\'épargne',
                    onPressed: () => _openPlanForm(context),
                  ),

                ],
              ),
              const SizedBox(height: 8),

              // Affichage des plans d'épargne (Logique existante inchangée [cite: 681-715])
              if (savingsPlans.isEmpty)
                Card(

                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [

                        Icon(
                          Icons.savings_outlined,
                          size: 64,
                          color: Colors.grey.shade400,

                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun plan d\'épargne configuré',

                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Créez un plan pour simuler vos investissements futurs',

                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
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
                )
              else
                ...savingsPlans.map((plan) {
                  // Trouver l'actif correspondant au ticker du plan
                  final targetAsset = _findAssetByTicker(portfolio, plan.targetTicker);
                  final assetName = targetAsset?.name ?? 'Actif inconnu';
                  final assetYield = targetAsset?.estimatedAnnualYield ?? 0.0;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.add_shopping_cart,
                        color: plan.isActive ? Colors.cyan : Colors.grey,

                      ),
                      title: Text(
                        plan.name,
                        overflow: TextOverflow.ellipsis,

                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            'Cible : $assetName (${plan.targetTicker})',
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),
                          Row(
                            children: [

                              Text(
                                '${plan.monthlyAmount.toStringAsFixed(0)} €/mois',
                                style: theme.textTheme.bodySmall?.copyWith(

                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),

                              ),
                              const SizedBox(width: 8),
                              Text(

                                '• ${(assetYield * 100).toStringAsFixed(1)}% /an',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,

                                ),
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

                                Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                const Text('Modifier'),

                              ],
                            ),
                            onTap: () {
                              // Délai pour fermer le menu avant d'ouvrir le formulaire
                              Future.delayed(const Duration(milliseconds: 100), () {
                                _openPlanForm(context, existingPlan: plan);
                              });
                            },
                          ),
                          PopupMenuItem(
                            child: Row(

                              children: [
                                Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                                const SizedBox(width: 8),

                                const Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ],
                            ),

                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 100), () {
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

                  );
                }),

              const SizedBox(height: 24),

              Text(
                'Projection du Portefeuille (à $_selectedDuration ans)',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // --- MODIFIÉ : Graphique implémenté ---
                      SizedBox(
                        height: 250,
                        child: projectionData.isEmpty
                            ? const Center(
                            child: Text('Aucune donnée à projeter.'))
                            : BarChart(
                          _buildChartData(projectionData, theme),
                        ),
                      ),
                      // --- FIN MODIFICATION ---
                      const SizedBox(height: 16),
                      // --- MODIFIÉ : Contrôles de durée ---
                      ToggleButtons(
                        isSelected:
                        _durations.map((d) => d == _selectedDuration).toList(),
                        onPressed: (index) {
                          setState(() {
                            _selectedDuration = _durations[index];
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        constraints:
                        const BoxConstraints(minHeight: 40, minWidth: 60),
                        children:
                        _durations.map((d) => Text('$d ans')).toList(),
                      ),
                      // --- FIN MODIFICATION ---
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // NOUVEAU : Fonction de construction du graphique
  BarChartData _buildChartData(List<ProjectionData> data, ThemeData theme) {
    final lastData = data.last;
    final maxValue = lastData.totalValue;

    final barGroups = data.map((d) {
      return BarChartGroupData(
        x: d.year,
        barRods: [
          BarChartRodData(
            toY: d.totalValue,
            borderRadius: BorderRadius.zero,
            width: 18,
            rodStackItems: [
              // 1. Capital initial (Portefeuille)
              BarChartRodStackItem(
                0,
                d.baseValue,
                theme.colorScheme.primary.withOpacity(0.6),
              ),
              // 2. Capital investi (Plans)
              BarChartRodStackItem(
                d.baseValue,
                d.baseValue + d.investedCapital,
                theme.colorScheme.secondary.withOpacity(0.8),
              ),
              // 3. Gains
              BarChartRodStackItem(
                d.baseValue + d.investedCapital,
                d.totalValue,
                Colors.green.shade400,
              ),
            ],
          ),
        ],
      );
    }).toList();

    return BarChartData(
      maxY: maxValue * 1.1, // Marge de 10%
      barGroups: barGroups,
      titlesData: FlTitlesData(
        // --- DÉBUT CORRECTION BLOC leftTitles ---
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

              // --- CORRECTION (selon votre suggestion) ---
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.right,
                ),
              );
              // --- FIN CORRECTION ---
            },
          ),
        ),
        // --- FIN CORRECTION BLOC leftTitles ---

        // --- DÉBUT CORRECTION BLOC bottomTitles ---
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

              // --- CORRECTION (selon votre suggestion) ---
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  year.toString(),
                  style: theme.textTheme.bodySmall,
                ),
              );
              // --- FIN CORRECTION ---
            },
          ),
        ),
        // --- FIN CORRECTION BLOC bottomTitles ---

        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxValue / 5,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.1),
          strokeWidth: 1,
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final d = data[groupIndex];
            return BarTooltipItem(
              'Année ${d.year}\n'
                  'Total: ${CurrencyFormatter.format(d.totalValue)}\n'
                  'Gains: ${CurrencyFormatter.format(d.totalGain)}\n'
                  'Investi: ${CurrencyFormatter.format(d.investedCapital)}\n'
                  'Initial: ${CurrencyFormatter.format(d.baseValue)}',
              theme.textTheme.bodySmall!.copyWith(color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}