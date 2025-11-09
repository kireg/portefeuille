// lib/features/04_correction/ui/widgets/institution_card.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'account_card.dart';

/// Affiche une carte éditable pour une Institution
class InstitutionCard extends StatelessWidget {
  final Institution institution;
  final VoidCallback onDelete;
  final VoidCallback onAddAccount;
  final void Function(int) onDeleteAccount;
  final void Function(int) onAddAsset;
  final void Function(int, int) onDeleteAsset;
  final VoidCallback onDataChanged;

  const InstitutionCard({
    super.key,
    required this.institution,
    required this.onDelete,
    required this.onAddAccount,
    required this.onDeleteAccount,
    required this.onAddAsset,
    required this.onDeleteAsset,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      color: theme.colorScheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Row(
          children: [
            Expanded(
                child: Text(institution.name,
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis)),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
              tooltip: 'Supprimer l\'institution',
              onPressed: onDelete,
            ),
            Flexible(
              child: Text(
                CurrencyFormatter.format(institution.totalValue),
                style: theme.textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        children: [
          ...institution.accounts.map((account) {
            final accIndex = institution.accounts.indexOf(account);
            return AccountCard(
              account: account,
              onDelete: () => onDeleteAccount(accIndex),
              onAddAsset: () => onAddAsset(accIndex),
              onDeleteAsset: (assetIndex) => onDeleteAsset(accIndex, assetIndex),
              onDataChanged: onDataChanged,
            );
          }).toList(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: OutlinedButton.icon(
              onPressed: onAddAccount,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un compte'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}