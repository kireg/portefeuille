import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_text_field.dart';

class CashFields extends StatelessWidget {
  const CashFields({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();

    return Column(
      children: [
        AppTextField(
          controller: state.amountController,
          label: 'Montant',
          suffixText: state.accountCurrency,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Invalide';
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingM),
      ],
    );
  }
}