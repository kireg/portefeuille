import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';

import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';

import 'form_sections/_account_selector.dart';
import 'form_sections/_common_fields.dart';
import 'form_sections/_dynamic_fields.dart';
import 'form_sections/_form_header.dart';
import 'form_sections/_type_selector.dart';

class TransactionFormBody extends StatelessWidget {
  final Transaction? existingTransaction;

  const TransactionFormBody({super.key, this.existingTransaction});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => TransactionFormState(
        existingTransaction: existingTransaction,
        apiService: ctx.read<ApiService>(),
        settingsProvider: ctx.read<SettingsProvider>(),
        portfolioProvider: ctx.read<PortfolioProvider>(),
      ),
      child: Consumer<TransactionFormState>(
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
      ),
    );
  }
}