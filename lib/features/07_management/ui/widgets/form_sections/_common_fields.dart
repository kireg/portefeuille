// lib/features/07_management/ui/widgets/form_sections/_common_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:provider/provider.dart';

class CommonFields extends StatelessWidget {
  const CommonFields({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();
    final readState = context.read<TransactionFormState>();

    return Column(
      children: [
        TextFormField(
          controller: state.dateController,
          decoration: const InputDecoration(
            labelText: 'Date *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: () => readState.selectDate(context),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: state.feesController,
          decoration: InputDecoration(
            labelText: 'Frais',
            border: const OutlineInputBorder(),
            suffixText: state.accountCurrency,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis (0.0 si aucun)';
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Nombre invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: state.notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (Optionnel)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}