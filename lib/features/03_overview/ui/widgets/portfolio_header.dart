import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart'; // Import pour le format pourcentage

class PortfolioHeader extends StatelessWidget {
  final Portfolio portfolio;

  const PortfolioHeader({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // CONNEXION AUX VRAIES DONNÉES
    final totalValue = portfolio.totalValue;
    final totalPL = portfolio.profitAndLoss;
    final totalPLPercentage = portfolio.profitAndLossPercentage;
    final annualYield = portfolio.estimatedAnnualYield;

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
                Expanded(
                  child: _buildStat(
                    context,
                    'Plus/Moins-value',
                    // Utilisation de NumberFormat.percentPattern pour un affichage correct
                    '${CurrencyFormatter.format(totalPL)} (${NumberFormat.percentPattern().format(totalPLPercentage)})',
                    totalPL >= 0 ? Colors.green[400]! : Colors.red[400]!,
                  ),
                ),
                Expanded(
                  child: _buildStat(
                    context,
                    'Rendement Annuel Estimé',
                    NumberFormat.percentPattern().format(annualYield),
                    Colors.deepPurple[400]!,
                  ),
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
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}