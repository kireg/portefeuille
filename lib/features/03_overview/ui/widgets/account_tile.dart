// lib/features/03_overview/ui/widgets/account_tile.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/ui/widgets/account_type_chip.dart';
import 'asset_list_item.dart';
// NOUVEL IMPORT
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';


class AccountTile extends StatelessWidget {
  final Account account;
  /// La devise de base de l'utilisateur (ex: "USD")
  final String baseCurrency;
  /// La devise native de ce compte (ex: "EUR")
  final String accountCurrency;

  const AccountTile({
    super.key,
    required this.account,
    required this.baseCurrency,
    required this.accountCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();

    // ▼▼▼ MODIFIÉ : Lecture depuis le Provider ▼▼▼
    final provider = context.watch<PortfolioProvider>();

    // Récupère la valeur CONVERTIE de ce compte
    final convertedTotalValue = provider.getConvertedAccountValue(account.id);
    // ▲▲▲ FIN MODIFICATION ▲▲▲

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
      trailing: Text(
        // Affiche la valeur totale CONVERTIE
        CurrencyFormatter.format(convertedTotalValue, baseCurrency),
        style: theme.textTheme.bodyLarge,
        overflow: TextOverflow.ellipsis,
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
            // Affiche le solde de liquidités dans la devise NATIVE du compte
            CurrencyFormatter.format(account.cashBalance, accountCurrency),
            style:
            TextStyle(color: Colors.grey[300], fontStyle: FontStyle.italic),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(height: 1),
        // AssetListItem doit être mis à jour pour utiliser les valeurs converties
        ...account.assets
            .map((asset) => AssetListItem(
          asset: asset,
          accountCurrency: accountCurrency, // Devise du compte
          baseCurrency: baseCurrency, // Devise de l'utilisateur
        ))
            .toList(),
      ],
    );
  }
}