// lib/features/03_overview/ui/widgets/account_tile.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/services/route_manager.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/ui/widgets/account_type_chip.dart';
import 'asset_list_item.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

// ▼▼▼ ENUM DÉPLACÉ ICI (EN DEHORS DE LA CLASSE) ▼▼▼
enum _AccountAction { edit, delete }
// ▲▲▲ FIN DÉPLACEMENT ▲▲▲

class AccountTile extends StatelessWidget {
  final String institutionId;
  final Account account;

  /// La devise de base de l'utilisateur (ex: "USD")
  final String baseCurrency;

  /// La devise native de ce compte (ex: "EUR")
  final String accountCurrency;

  const AccountTile({
    super.key,
    required this.institutionId,
    required this.account,
    required this.baseCurrency,
    required this.accountCurrency,
  });

  // Helper pour l'action "Supprimer"
  void _onDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Voulez-vous vraiment supprimer le compte "${account.name}" et toutes ses transactions associées ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
            onPressed: () {
              Provider.of<PortfolioProvider>(context, listen: false)
                  .deleteAccount(institutionId, account.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  // Helper pour l'action "Modifier"
  void _onEdit(BuildContext context) {
    // Utiliser route nommée avec arguments au lieu d'importer AddAccountScreen
    Navigator.of(context).pushNamed(
      RouteManager.addAccount,
      arguments: {
        'institutionId': institutionId,
        'accountToEdit': account,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();
    final provider = context.watch<PortfolioProvider>();

    final convertedTotalValue = provider.getConvertedAccountValue(account.id);

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
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          AccountTypeChip(
            accountType: account.type,
            isNoviceModeEnabled:
            settingsProvider.userLevel == UserLevel.novice,
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.format(convertedTotalValue, baseCurrency),
            style: theme.textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
          // Le code ici est maintenant correct car _AccountAction est défini
          PopupMenuButton<_AccountAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              if (action == _AccountAction.edit) {
                _onEdit(context);
              } else if (action == _AccountAction.delete) {
                _onDelete(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _AccountAction.edit,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _AccountAction.delete,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      childrenPadding: const EdgeInsets.only(left: 16.0),
      children: [
        ListTile(
          dense: true,
          leading: Icon(Icons.account_balance_wallet_outlined,
              color: Colors.grey[400]),
          title: Text('Liquidités',
              style: TextStyle(
                  color: Colors.grey[400], fontStyle: FontStyle.italic)),
          trailing: Text(
            CurrencyFormatter.format(account.cashBalance, accountCurrency),
            style:
            TextStyle(color: Colors.grey[300], fontStyle: FontStyle.italic),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(height: 1),
        ...account.assets
            .map((asset) => AssetListItem(
          asset: asset,
          accountCurrency: accountCurrency,
          baseCurrency: baseCurrency,
        ))
            .toList(),
      ],
    );
  }
}