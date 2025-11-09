import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';
// import 'package:fl_chart/fl_chart.dart';

class PlannerTab extends StatelessWidget {
  const PlannerTab({super.key});

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
              Text(
                'Plans d\'Épargne Mensuels',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              
              // Affichage des plans d'épargne
              if (savingsPlans.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Aucun plan d\'épargne configuré',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...savingsPlans.map((plan) => Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.add_shopping_cart,
                      color: plan.isActive ? Colors.cyan : Colors.grey,
                    ),
                    title: Text(
                      plan.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Cible : ${plan.targetAssetName} (${plan.targetTicker})',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${plan.monthlyAmount.toStringAsFixed(0)} €/mois',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(plan.estimatedAnnualReturn * 100).toStringAsFixed(1)}% /an',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () { /* TODO: Modifier le plan */ },
                  ),
                )),

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
