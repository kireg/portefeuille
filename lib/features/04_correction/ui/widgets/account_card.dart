// lib/features/04_correction/ui/widgets/account_card.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'account_type_label.dart';
import 'asset_grid.dart';
import 'cash_field.dart';

/// Affiche une carte éditable pour un Compte (Account)
class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onDelete;
  final VoidCallback onAddAsset;
  final void Function(int) onDeleteAsset;
  final VoidCallback onDataChanged;

  const AccountCard({
    super.key,
    required this.account,
    required this.onDelete,
    required this.onAddAsset,
    required this.onDeleteAsset,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Card(
        color: Color.lerp(
            theme.colorScheme.surface, theme.colorScheme.background, 0.5),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: theme.colorScheme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AccountTypeLabel(
                        label: account.type.displayName,
                        description: account.type.description,
                        backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.12),
                        textColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: theme.colorScheme.error,
                    tooltip: 'Supprimer le compte',
                    onPressed: onDelete,
                  ),
                  Flexible(
                    child: Text(
                      CurrencyFormatter.format(account.totalValue),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: theme.colorScheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (account.type != AccountType.crypto)
                    CashField(
                      initialValue: account.cashBalance,
                      onChanged: (newValue) {
                        account.cashBalance = newValue;
                        onDataChanged();
                      },
                    ),
                  AssetGrid(
                    assets: account.assets,
                    onDeleteAsset: onDeleteAsset,
                    onDataChanged: onDataChanged,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onAddAsset,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter un actif'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}