import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:portefeuille/features/07_management/ui/widgets/transaction_form_ui.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';

class EditTransactionScreen extends StatelessWidget {
  final Transaction existingTransaction;

  const EditTransactionScreen({super.key, required this.existingTransaction});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => TransactionFormState(
        existingTransaction: existingTransaction,
        apiService: ctx.read<ApiService>(),
        settingsProvider: ctx.read<SettingsProvider>(),
        portfolioProvider: ctx.read<PortfolioProvider>(),
        transactionProvider: ctx.read<TransactionProvider>(),
      ),
      child: Consumer<TransactionFormState>(
        builder: (context, state, child) {
          return PopScope(
            canPop: !state.hasChanges,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text('Modifications non enregistrées', style: AppTypography.h3),
                  content: Text(
                    'Voulez-vous enregistrer les modifications avant de quitter ?',
                    style: AppTypography.body,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true), // Quitter sans sauver
                      child: Text('Ne pas enregistrer', style: AppTypography.label.copyWith(color: AppColors.error)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(false); // Rester
                        state.submitForm(context); // Sauver
                      },
                      child: Text('Enregistrer', style: AppTypography.label.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              );

              if (shouldPop == true) {
                state.discardChanges();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text('Modifier la transaction', style: AppTypography.h3),
                backgroundColor: AppColors.surface,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () async {
                     if (!state.hasChanges) {
                       Navigator.of(context).pop();
                       return;
                     }
                     // Trigger PopScope logic
                     Navigator.of(context).maybePop();
                  },
                ),
              ),
              body: const SingleChildScrollView(
                child: Padding(
                  padding: AppSpacing.paddingAll16,
                  child: TransactionFormUI(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}