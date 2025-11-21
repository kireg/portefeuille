import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_dropdown.dart';

class TypeSelector extends StatelessWidget {
  const TypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();

    return AppDropdown<TransactionType>(
      label: 'Type de transaction',
      value: state.selectedType,
      prefixIcon: Icons.category_outlined,
      items: TransactionType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.displayName),
        );
      }).toList(),
      onChanged: (type) =>
          context.read<TransactionFormState>().selectType(type),
    );
  }
}