// lib/features/03_overview/ui/widgets/portfolio_header.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
// import 'package:portefeuille/core/data/models/portfolio.dart'; // Supprimé
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
// Import pour le format pourcentage
// NOUVEAUX IMPORTS
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
// import 'package:portefeuille/features/00_app/providers/settings_provider.dart'; // Plus nécessaire

class PortfolioHeader extends StatelessWidget {
  // Le constructeur n'a plus besoin de 'portfolio'
  const PortfolioHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ▼▼▼ MODIFIÉ : Lecture depuis le Provider ▼▼▼
    // Nous utilisons 'watch' pour que ce widget se reconstruise
    // lorsque les valeurs converties changent.
    final provider = context.watch<PortfolioProvider>();

    // Récupérer les valeurs CONVERTIES depuis le provider
    final baseCurrency = provider.currentBaseCurrency;
    final totalValue = provider.activePortfolioTotalValue;
    final totalPL = provider.activePortfolioTotalPL;
    final totalPLPercentage = provider.activePortfolioTotalPLPercentage;
    final annualYield = provider.activePortfolioEstimatedAnnualYield;
    // ▲▲▲ FIN MODIFICATION ▲▲▲

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Valeur Totale du Portefeuille',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              // Utilise les valeurs converties
              CurrencyFormatter.format(totalValue, baseCurrency),
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildStat(
                    context,
                    'Plus/Moins-value',
                    // Utilise les valeurs converties
                    '${CurrencyFormatter.format(totalPL, baseCurrency)} (${NumberFormat.percentPattern().format(totalPLPercentage)})',
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

  Widget _buildStat(
      BuildContext context, String label, String value, Color valueColor) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}