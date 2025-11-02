import 'package:flutter/material.dart';
import '../../models/asset.dart';
import '../../utils/currency_formatter.dart';

class AssetListItem extends StatelessWidget {
  final Asset asset;

  const AssetListItem({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pnl = asset.profitAndLoss;
    final pnlColor = pnl >= 0 ? Colors.green[400] : Colors.red[400];

    return ListTile(
      title: Text(asset.name),
      subtitle: Text('${asset.quantity} x ${CurrencyFormatter.format(asset.averagePrice)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(asset.totalValue),
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyFormatter.format(pnl)} (${(asset.profitAndLossPercentage * 100).toStringAsFixed(2)}%)',
            style: theme.textTheme.bodySmall?.copyWith(color: pnlColor),
          ),
        ],
      ),
    );
  }
}
