import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../utils/currency_formatter.dart';
import 'asset_list_item.dart';

class AccountTile extends StatelessWidget {
  final Account account;

  const AccountTile({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      backgroundColor: theme.scaffoldBackgroundColor.withAlpha(20),
      title: Text(
        account.name,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(account.type.toString().split('.').last),
      trailing: Text(
        CurrencyFormatter.format(account.totalValue),
        style: theme.textTheme.bodyLarge,
      ),
      children: [
         Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Liquidités', style: TextStyle(color: Colors.grey[400])),
              Text(
                CurrencyFormatter.format(account.cashBalance),
                style: TextStyle(color: Colors.grey[300]),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ...account.assets.map((asset) => AssetListItem(asset: asset)),
      ],
    );
  }
}
