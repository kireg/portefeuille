// lib/features/07_management/ui/widgets/form_sections/_form_header.dart
import 'package:flutter/material.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:provider/provider.dart';

class FormHeader extends StatelessWidget {
  const FormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          state.isEditing ? 'Modifier la Transaction' : 'Nouvelle Transaction',
          style: theme.textTheme.titleLarge,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}