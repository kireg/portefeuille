// lib/features/03_overview/ui/widgets/asset_list_item.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
// NOUVEL IMPORT
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';


class AssetListItem extends StatelessWidget {
  final Asset asset;
  /// La devise native du compte parent (ex: "EUR")
  final String accountCurrency;
  /// La devise de base de l'utilisateur (ex: "USD")
  final String baseCurrency;

  const AssetListItem({
    super.key,
    required this.asset,
    required this.accountCurrency,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ▼▼▼ MODIFIÉ : Lecture depuis le Provider ▼▼▼
    // Nous n'avons pas l'ID de l'asset, mais nous avons l'ID du compte
    // et le provider a les taux.
    // Nous devons recalculer la conversion ici.
    final provider = context.watch<PortfolioProvider>();

    // Les valeurs du modèle 'asset' sont en devise de COMPTE (accountCurrency)
    final totalValueInAccountCurrency = asset.totalValue;
    final pnlInAccountCurrency = asset.profitAndLoss;

    // Récupère la valeur totale CONVERTIE de ce compte
    final accountValueConverted = provider.getConvertedAccountValue(asset.transactions.first.accountId);
    // Récupère la valeur native de ce compte
    final accountValueNative = provider.activePortfolio?.institutions
        .expand((i) => i.accounts)
        .firstWhere((acc) => acc.id == asset.transactions.first.accountId)
        .totalValue ?? 0.0;

    // Calcule le taux de conversion global pour ce compte
    final double conversionRate = (accountValueNative == 0)
        ? 1.0
        : accountValueConverted / accountValueNative;

    // Applique le taux aux valeurs de l'asset
    final totalValueConverted = totalValueInAccountCurrency * conversionRate;
    final pnlConverted = pnlInAccountCurrency * conversionRate;
    // Le % de P/L est indépendant de la devise
    final pnlPercentage = asset.profitAndLossPercentage;

    final pnlColor = pnlConverted >= 0 ? Colors.green.shade400 : Colors.red.shade400;
    // ▲▲▲ FIN MODIFICATION ▲▲▲

    return ListTile(
      dense: true,
      title: Text(
        asset.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          children: <TextSpan>[
            // Le PRU est affiché dans la devise du COMPTE (plus simple)
            TextSpan(
                text:
                '${asset.quantity} x ${CurrencyFormatter.format(asset.averagePrice, accountCurrency)}'),
            if (asset.estimatedAnnualYield > 0)
              TextSpan(
                text:
                '  •  Rdt. Annuel Est. ${NumberFormat.percentPattern().format(asset.estimatedAnnualYield)}',
                style: TextStyle(color: Colors.deepPurple[400]),
              ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              // Utilise la valeur CONVERTIE et la devise de BASE
              CurrencyFormatter.format(totalValueConverted, baseCurrency),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              // Utilise la P/L CONVERTIE et la devise de BASE
              '${CurrencyFormatter.format(pnlConverted, baseCurrency)} (${(pnlPercentage * 100).toStringAsFixed(2)}%)}',
              style: theme.textTheme.bodySmall?.copyWith(color: pnlColor),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}