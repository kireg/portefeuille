import 'package:flutter/material.dart';
import '../../models/asset.dart';

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
      subtitle: Text('${asset.quantity} x ${asset.averagePrice.toStringAsFixed(2)} €'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${asset.totalValue.toStringAsFixed(2)} €',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${pnl.toStringAsFixed(2)} € (${(asset.profitAndLossPercentage * 100).toStringAsFixed(2)}%)',
            style: theme.textTheme.bodySmall?.copyWith(color: pnlColor),
          ),
        ],
      ),
    );
  }
}
