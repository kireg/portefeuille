// lib/features/03_overview/ui/widgets/account_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/services/modal_service.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/ui/widgets/account_type_chip.dart';
import 'package:portefeuille/core/ui/widgets/asset_list_item.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

// Enum pour les actions du menu contextuel
enum _AccountAction { edit, delete }

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
    ModalService.showAddAccount(context,
        institutionId: institutionId, accountToEdit: account);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();
    final provider = context.watch<PortfolioProvider>();

    // 1. Récupération des valeurs converties via le Provider
    final convertedTotalValue = provider.getConvertedAccountValue(account.id);
    final convertedPL = provider.getConvertedAccountPL(account.id);
    final convertedInvested = provider.getConvertedAccountInvested(account.id);

    // 2. Calcul du pourcentage
    final plPercentage =
    (convertedInvested == 0) ? 0.0 : convertedPL / convertedInvested;

    return ExpansionTile(
      backgroundColor: theme.scaffoldBackgroundColor.withAlpha(20),
      controlAffinity: ListTileControlAffinity.leading,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.name,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
          const SizedBox(height: 4),
          AccountTypeChip(
            accountType: account.type,
            isNoviceModeEnabled: settingsProvider.userLevel == UserLevel.novice,
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Colonne Montant + Performance
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(convertedTotalValue, baseCurrency),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              // Affichage de la P/L
              _buildProfitAndLoss(
                  convertedPL, plPercentage, theme, baseCurrency),
            ],
          ),
          // Menu d'actions
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
          trailing: SizedBox(
            width: 100, // Largeur fixe pour aligner avec les assets
            child: Text(
              CurrencyFormatter.format(account.cashBalance, accountCurrency),
              style: TextStyle(
                  color: Colors.grey[300], fontStyle: FontStyle.italic),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ),
        const Divider(height: 1),
        ...account.assets
            .map((asset) => AssetListItem(
          asset: asset,
          accountCurrency: accountCurrency,
          baseCurrency: baseCurrency,
        ))
            ,
      ],
    );
  }

  // Helper pour afficher la P/L (couleur + flèche)
  Widget _buildProfitAndLoss(
      double pnl, double pnlPercentage, ThemeData theme, String baseCurrency) {
    if (pnl == 0 && pnlPercentage == 0) return const SizedBox.shrink();

    final isPositive = pnl >= 0;
    final color = isPositive ? Colors.green.shade400 : Colors.red.shade400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
          size: 12,
        ),
        const SizedBox(width: 2),
        Text(
          '${CurrencyFormatter.format(pnl, baseCurrency)} (${NumberFormat.percentPattern().format(pnlPercentage)})',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontSize: 11,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}