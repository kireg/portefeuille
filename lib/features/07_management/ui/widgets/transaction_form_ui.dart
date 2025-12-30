import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_button.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';

import 'form_sections/_account_selector.dart';
import 'form_sections/_common_fields.dart';
import 'form_sections/_dynamic_fields.dart';
import 'form_sections/_form_header.dart';
import 'form_sections/_type_selector.dart';

class TransactionFormUI extends StatelessWidget {
  const TransactionFormUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionFormState>(
      builder: (context, state, child) {
        return Form(
          key: state.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormHeader(),

              const SizedBox(height: AppDimens.paddingL),

              const AccountSelector(),
              const SizedBox(height: AppDimens.paddingM),

              const TypeSelector(),
              const SizedBox(height: AppDimens.paddingM),

              const DynamicFields(),

              const CommonFields(),
              const SizedBox(height: AppDimens.paddingXL),

              AppButton(
                label: state.isEditing ? 'Enregistrer' : 'Créer',
                icon: state.isEditing ? Icons.save : Icons.add,
                onPressed: () => state.submitForm(context),
              ),

              const SizedBox(height: AppDimens.paddingL),
            ],
          ),
        );
      },
    );
  }
}
