import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:portefeuille/core/Design_Center/widgets/inputs/app_dropdown.dart';

class AccountSelector extends StatelessWidget {
  const AccountSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();

    return AppDropdown<Account>(
      label: 'Compte',
      value: state.selectedAccount,
      prefixIcon: Icons.account_balance_wallet_outlined,
      isExpanded: true,
      // On utilise la méthode existante du state qui génère déjà les DropdownMenuItem
      items: state.buildGroupedAccountItems(context),
      onChanged: (account) =>
          context.read<TransactionFormState>().selectAccount(account),
      validator: (value) => value == null ? 'Requis' : null,
    );
  }
}