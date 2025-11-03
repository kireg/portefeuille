import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/institution.dart';
import '../../utils/currency_formatter.dart';
import 'account_tile.dart';

class InstitutionTile extends StatelessWidget {
  final Institution institution;
  final double portfolioTotalValue;

  const InstitutionTile({
    super.key,
    required this.institution,
    required this.portfolioTotalValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentageOfPortfolio = portfolioTotalValue > 0
        ? (institution.totalValue / portfolioTotalValue)
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Text(
          institution.name,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${NumberFormat.percentPattern(Localizations.localeOf(context).languageCode).format(percentageOfPortfolio)} du portefeuille',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade400),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(institution.totalValue),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            _buildProfitAndLoss(institution.profitAndLoss, institution.profitAndLossPercentage, theme),
          ],
        ),
        childrenPadding: const EdgeInsets.only(left: 16.0),
        children: institution.accounts
            .map((account) => AccountTile(account: account))
            .toList(),
      ),
    );
  }

  Widget _buildProfitAndLoss(double pnl, double pnlPercentage, ThemeData theme) {
    if (pnl == 0) return const SizedBox.shrink();
    final isPositive = pnl >= 0;
    final color = isPositive ? Colors.green.shade400 : Colors.red.shade400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '${CurrencyFormatter.format(pnl)} (${NumberFormat.percentPattern().format(pnlPercentage)})',
          style: theme.textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
