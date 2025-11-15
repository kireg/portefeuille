// lib/features/07_management/ui/widgets/form_sections/_type_selector.dart
import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:provider/provider.dart';

class TypeSelector extends StatelessWidget {
  const TypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();

    return DropdownButtonFormField<TransactionType>(
      value: state.selectedType,
      items: TransactionType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.displayName),
        );
      }).toList(),
      onChanged: (type) =>
          context.read<TransactionFormState>().selectType(type),
      decoration: const InputDecoration(
        labelText: 'Type de transaction *',
        border: OutlineInputBorder(),
      ),
    );
  }
}