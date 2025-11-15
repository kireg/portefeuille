// lib/features/07_management/ui/widgets/transaction_form_body.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:provider/provider.dart';
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
    // Crée une instance locale du provider de formulaire
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
                // 1. L'en-tête
                const FormHeader(),
                const SizedBox(height: 24),

                // 2. Les sélecteurs
                const AccountSelector(),
                const SizedBox(height: 16),
                const TypeSelector(),
                const SizedBox(height: 16),

                // 3. Les champs dynamiques (le switch interne choisit le bon formulaire)
                const DynamicFields(),

                // 4. Les champs communs (Date, Frais, Notes)
                const CommonFields(),
                const SizedBox(height: 24),

                // 5. Le bouton
                ElevatedButton.icon(
                  onPressed: () => state.submitForm(context),
                  icon: const Icon(Icons.save),
                  label: Text(state.isEditing ? 'Enregistrer' : 'Créer'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}