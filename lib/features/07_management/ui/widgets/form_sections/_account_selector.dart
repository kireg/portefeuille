// lib/features/07_management/ui/widgets/form_sections/_account_selector.dart
import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:provider/provider.dart';

class AccountSelector extends StatelessWidget {
  const AccountSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();

    return DropdownButtonFormField<Account>(
      value: state.selectedAccount,
      isExpanded: true,
      items: state.buildGroupedAccountItems(context),
      onChanged: (account) =>
          context.read<TransactionFormState>().selectAccount(account),
      decoration: const InputDecoration(
        labelText: 'Compte *',
        border: OutlineInputBorder(),
      ),
      validator: (value) => value == null ? 'Compte requis' : null,
    );
  }
}