// lib/features/03_overview/ui/widgets/institution_tile.dart
// NOUVEAU FICHIER (remplace l'ancien)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'account_tile.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

class InstitutionTile extends StatelessWidget {
  final Institution institution;

  const InstitutionTile({
    super.key,
    required this.institution,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ▼▼▼ MODIFIÉ : Lecture depuis le Provider ▼▼▼
    final portfolioProvider = context.watch<PortfolioProvider>();
    final baseCurrency = portfolioProvider.currentBaseCurrency;

    // Calcul des totaux CONVERTIS pour CETTE institution
    final institutionTotalValue = institution.accounts.fold(0.0,
            (sum, acc) => sum + portfolioProvider.getConvertedAccountValue(acc.id));

    final institutionTotalPL = institution.accounts.fold(0.0,
            (sum, acc) => sum + portfolioProvider.getConvertedAccountPL(acc.id));

    final institutionTotalInvested = institution.accounts.fold(0.0,
            (sum, acc) => sum + portfolioProvider.getConvertedAccountInvested(acc.id));

    final institutionPLPercentage = (institutionTotalInvested == 0)
        ? 0.0
        : institutionTotalPL / institutionTotalInvested;
    // ▲▲▲ FIN MODIFICATION ▲▲▲

    return AppTheme.buildInfoContainer(
      context: context,
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            institution.name,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    // Utilise la valeur convertie
                    CurrencyFormatter.format(institutionTotalValue, baseCurrency),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  // Affiche la P/L convertie
                  _buildProfitAndLoss(institutionTotalPL,
                      institutionPLPercentage, theme, baseCurrency),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            Divider(height: 1, indent: 16),
            ...institution.accounts.map((account) {
              // Passe la devise de BASE (pour les totaux)
              // et la devise du COMPTE (pour le cash)
              return AccountTile(
                account: account,
                baseCurrency: baseCurrency,
                accountCurrency: account.activeCurrency,
              );
            }).toList(),
            ListTile(
              leading: Icon(
                Icons.add,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
              title: Text(
                'Ajouter un compte',
                style: TextStyle(
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              ),
              onTap: () {
                // (Logique d'ajout inchangée)
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper P/L (inchangé, mais recevra des valeurs converties)
  Widget _buildProfitAndLoss(
      double pnl, double pnlPercentage, ThemeData theme, String baseCurrency) {
    if (pnl == 0 && pnlPercentage == 0) return const SizedBox(height: 16);
    final isPositive = pnl >= 0;
    final color = isPositive ? Colors.green.shade400 : Colors.red.shade400;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: color, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${CurrencyFormatter.format(pnl, baseCurrency)} (${NumberFormat.percentPattern().format(pnlPercentage)})',
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}