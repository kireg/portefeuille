// lib/features/07_management/ui/widgets/form_sections/_dividend_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:provider/provider.dart';

class DividendFields extends StatelessWidget {
  const DividendFields({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();

    return Column(
      children: [
        TextFormField(
          controller: state.amountController,
          decoration: InputDecoration(
            labelText: 'Montant reçu *',
            border: const OutlineInputBorder(),
            suffixText: state.accountCurrency,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Montant requis';
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Nombre invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: state.tickerController,
          decoration: const InputDecoration(
            labelText: 'Ticker (Optionnel)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: state.nameController,
          decoration: const InputDecoration(
            labelText: 'Nom (ex: Dividende Apple)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}