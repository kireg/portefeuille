import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/asset.dart';
import '../../utils/currency_formatter.dart';

class AssetListItem extends StatelessWidget {
  final Asset asset;

  const AssetListItem({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pnl = asset.profitAndLoss;
    final pnlColor = pnl >= 0 ? Colors.green.shade400 : Colors.red.shade400;

    return ListTile(
      dense: true,
      title: Text(asset.name),
      subtitle: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          children: <TextSpan>[
            TextSpan(text: '${asset.quantity} x ${CurrencyFormatter.format(asset.averagePrice)}'),
            if (asset.estimatedAnnualYield > 0)
              TextSpan(
                text: '  •  Rdt. Annuel Est. ${NumberFormat.percentPattern().format(asset.estimatedAnnualYield)}',
                style: TextStyle(color: Colors.deepPurple[400]),
              ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(asset.totalValue),
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '${CurrencyFormatter.format(pnl)} (${(asset.profitAndLossPercentage * 100).toStringAsFixed(2)}%)}',
            style: theme.textTheme.bodySmall?.copyWith(color: pnlColor),
          ),
        ],
      ),
    );
  }
}
