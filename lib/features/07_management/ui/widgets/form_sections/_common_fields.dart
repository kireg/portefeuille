import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/widgets/inputs/app_text_field.dart';

class CommonFields extends StatelessWidget {
  const CommonFields({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();
    final readState = context.read<TransactionFormState>();

    return Column(
      children: [
        const SizedBox(height: AppDimens.paddingM),
        AppTextField(
          controller: state.dateController,
          label: 'Date',
          prefixIcon: Icons.calendar_today_outlined,
          readOnly: true,
          onTap: () => readState.selectDate(context),
        ),
        const SizedBox(height: AppDimens.paddingM),
        AppTextField(
          controller: state.feesController,
          label: 'Frais',
          suffixText: state.accountCurrency,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis (0.0 si aucun)';
            if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Invalide';
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingM),
        AppTextField(
          controller: state.notesController,
          label: 'Notes (Optionnel)',
          hint: 'Détails, contexte...',
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}