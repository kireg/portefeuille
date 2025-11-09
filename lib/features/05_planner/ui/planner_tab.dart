import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/data/models/asset.dart';
import '../../00_app/providers/portfolio_provider.dart';
import '../../07_management/ui/screens/add_savings_plan_screen.dart';
// import 'package:fl_chart/fl_chart.dart';

class PlannerTab extends StatelessWidget {
  const PlannerTab({super.key});

  /// Trouve un actif dans le portefeuille par son ticker
  Asset? _findAssetByTicker(portfolio, String ticker) {
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

  /// Ouvre le formulaire d'ajout ou de modification
  void _openPlanForm(BuildContext context, {existingPlan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddSavingsPlanScreen(existingPlan: existingPlan),
    );
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Ajouter un plan d\'épargne',
                    onPressed: () => _openPlanForm(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Affichage des plans d'épargne
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
                'Projection du Portefeuille',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
               Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // TODO: Ajouter le graphique en barres ici (BarChart)
                      Container(
                        height: 250,
                        color: Colors.black26,
                        child: const Center(child: Text('Graphique de projection à venir')),
                      ),
                      const SizedBox(height: 16),
                      // TODO: Ajouter des contrôles pour changer la durée (5, 10, 20, 30 ans)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [Text('5A'), Text('10A'), Text('20A'), Text('30A')],
                      )
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
}
