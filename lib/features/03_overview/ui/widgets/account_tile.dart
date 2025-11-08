// lib/features/03_overview/ui/widgets/account_tile.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/ui/widgets/account_type_chip.dart';
import 'asset_list_item.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_asset_screen.dart';

class AccountTile extends StatelessWidget {
  final Account account;
  const AccountTile({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      backgroundColor: theme.scaffoldBackgroundColor.withAlpha(20),
      controlAffinity: ListTileControlAffinity.leading,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.name,
            style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          AccountTypeChip(
              accountType: account.type, isNoviceModeEnabled: true),
        ],
      ),
      trailing: Text(
        CurrencyFormatter.format(account.totalValue),
        style: theme.textTheme.bodyLarge,
      ),
      childrenPadding: const EdgeInsets.only(left: 16.0),
      children: [
        ListTile(
          dense: true,
          leading: Icon(Icons.account_balance_wallet_outlined,
              color: Colors.grey[400]),
          title: Text('Liquidités',
              style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic)),
          trailing: Text(
            CurrencyFormatter.format(account.cashBalance),
            style:
            TextStyle(color: Colors.grey[300], fontStyle: FontStyle.italic),
          ),
        ),
        const Divider(height: 1),
        ...account.assets.map((asset) => AssetListItem(asset: asset)),
        ListTile(
          dense: true,
          leading: Icon(Icons.add, color: Colors.grey[400], size: 20),
          title: Text(
            'Ajouter un actif',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          // --- MODIFIÉ ---
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => AddAssetScreen(accountId: account.id),
            );
          },
          // --- FIN MODIFICATION ---
        ),
      ],
    );
  }
}