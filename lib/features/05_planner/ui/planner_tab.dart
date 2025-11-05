import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

class PlannerTab extends StatelessWidget {
  const PlannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Card(
            child: ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.cyan),
              title: const Text('Achat mensuel d\'ETF World'),
              subtitle: const Text('Cible : Amundi MSCI World (CW8)'),
              trailing: const Text('150 €/mois', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { /* TODO: Modifier le plan */ },
            ),
          ),
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
  }
}
