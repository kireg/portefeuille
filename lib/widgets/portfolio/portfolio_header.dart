import 'package:flutter/material.dart';
import '../../models/portfolio.dart';
import '../../utils/currency_formatter.dart';

class PortfolioHeader extends StatelessWidget {
  final Portfolio portfolio;

  const PortfolioHeader({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // NOTE: Le calcul de P/L et de rendement est simplifié ici.
    // Une vraie application nécessiterait une logique plus complexe.
    final totalValue = portfolio.totalValue;
    final totalPL = 5000.0; // Exemple
    final totalPLPercentage = 0.10; // Exemple
    final annualYield = 0.05; // Exemple

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Valeur Totale du Portefeuille',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(totalValue),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  context,
                  'Plus/Moins-value',
                  '${CurrencyFormatter.format(totalPL)} (${(totalPLPercentage * 100).toStringAsFixed(2)}%)',
                  totalPL >= 0 ? Colors.green[400]! : Colors.red[400]!,
                ),
                 _buildStat(
                  context,
                  'Rendement Annuel Estimé',
                   '${(annualYield * 100).toStringAsFixed(2)}%',
                  theme.colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, Color valueColor) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
