// lib/features/04_correction/ui/widgets/cash_field.dart

import 'package:flutter/material.dart';

/// Affiche le champ éditable pour les liquidités (Cash)
class CashField extends StatelessWidget {
  final double initialValue;
  final ValueChanged<double> onChanged;

  const CashField({super.key, required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0), // Ajout de padding en bas
      child: TextFormField(
        initialValue: initialValue.toStringAsFixed(2),
        decoration: InputDecoration(
          labelText: 'Liquidités',
          labelStyle: TextStyle(color: theme.colorScheme.primary),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide:
            BorderSide(color: theme.colorScheme.primary.withOpacity(0.18)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
            BorderSide(color: theme.colorScheme.primary, width: 1.4),
          ),
          isDense: false,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          prefixIcon:
          Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
          prefixIconConstraints:
          const BoxConstraints(minWidth: 40, minHeight: 40),
          suffixText: '€',
        ),
        style:
        theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        textAlignVertical: TextAlignVertical.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) {
          onChanged(double.tryParse(value.replaceAll(',', '.')) ?? initialValue);
        },
      ),
    );
  }
}