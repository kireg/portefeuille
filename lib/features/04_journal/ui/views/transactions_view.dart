import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core UI
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart'; // Ajouté
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';
import 'package:portefeuille/core/ui/widgets/transaction_list_item.dart';

// Data & Logic
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/07_management/ui/screens/edit_transaction_screen.dart';

enum TransactionSortOption {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
  type,
}

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  TransactionSortOption _sortOption = TransactionSortOption.dateDesc;

  List<Transaction> _sortTransactions(List<Transaction> transactions) {
    switch (_sortOption) {
      case TransactionSortOption.dateAsc:
        transactions.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TransactionSortOption.amountDesc:
        transactions.sort((a, b) => b.totalAmount.compareTo(b.totalAmount));
        break;
      case TransactionSortOption.amountAsc:
        transactions.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case TransactionSortOption.type:
        transactions.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;
      case TransactionSortOption.dateDesc:
      default:
        transactions.sort((a, b) => b.date.compareTo(a.date));
        break;
    }
    return transactions;
  }

  void _confirmDelete(BuildContext context, PortfolioProvider provider, Transaction transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Supprimer ?', style: AppTypography.h3),
        content: Text(
          'Cette action est irréversible.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuler', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTransaction(transaction.id);
              Navigator.of(ctx).pop();
            },
            child: Text('Supprimer', style: AppTypography.label.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _editTransaction(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => EditTransactionScreen(existingTransaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcul de l'espace nécessaire en haut
    final double topPadding = MediaQuery.of(context).padding.top + 90;

    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final portfolio = provider.activePortfolio;
        if (portfolio == null) {
          return const Center(child: Text("Aucun portefeuille."));
        }

        final accountsMap = <String, Account>{};
        for (var inst in portfolio.institutions) {
          for (var acc in inst.accounts) {
            accountsMap[acc.id] = acc;
          }
        }

        final List<Transaction> allTransactions = portfolio.institutions
            .expand((inst) => inst.accounts)
            .expand((acc) => acc.transactions)
            .toList();

        final sortedTransactions = _sortTransactions(allTransactions);

        // --- CAS 1 : LISTE VIDE ---
        if (allTransactions.isEmpty) {
          return AppScreen(
            withSafeArea: false,
            body: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: topPadding, bottom: AppDimens.paddingL),
                  child: Text('Historique', style: AppTypography.h2),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: AppCard(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            icon: Icons.receipt_long_outlined,
                            size: 48,
                            backgroundColor: AppColors.surfaceLight,
                          ),
                          const SizedBox(height: AppDimens.paddingM),
                          Text('Aucune transaction', style: AppTypography.h3),
                          const SizedBox(height: AppDimens.paddingS),
                          Text(
                            'Utilisez le bouton "+" pour commencer.',
                            style: AppTypography.body,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // --- CAS 2 : LISTE DES TRANSACTIONS ---
        return AppScreen(
          withSafeArea: false,
          body: Column(
            children: [
              // Titre avec padding haut
              Padding(
                padding: EdgeInsets.only(top: topPadding, bottom: AppDimens.paddingL),
                child: Text('Transactions', style: AppTypography.h2),
              ),

              // Barre de tri
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Trier par', style: AppTypography.body),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<TransactionSortOption>(
                          value: _sortOption,
                          dropdownColor: AppColors.surfaceLight,
                          icon: const Icon(Icons.sort, color: AppColors.primary),
                          style: AppTypography.bodyBold,
                          items: const [
                            DropdownMenuItem(value: TransactionSortOption.dateDesc, child: Text('Date (Récent)')),
                            DropdownMenuItem(value: TransactionSortOption.dateAsc, child: Text('Date (Ancien)')),
                            DropdownMenuItem(value: TransactionSortOption.amountDesc, child: Text('Montant (Haut)')),
                            DropdownMenuItem(value: TransactionSortOption.amountAsc, child: Text('Montant (Bas)')),
                            DropdownMenuItem(value: TransactionSortOption.type, child: Text('Type')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _sortOption = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.paddingM),

              // Liste
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppDimens.paddingM, 0, AppDimens.paddingM, 80),
                  itemCount: sortedTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = sortedTransactions[index];
                    final account = accountsMap[transaction.accountId];
                    final accountName = account?.name ?? 'Inconnu';
                    final accountCurrency = account?.activeCurrency ?? 'EUR';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
                      child: FadeInSlide(
                        delay: index * 0.05, // Cascade animation
                        child: TransactionListItem(
                          transaction: transaction,
                          accountName: accountName,
                          accountCurrency: accountCurrency,
                          onDelete: () => _confirmDelete(context, provider, transaction),
                          onEdit: () => _editTransaction(context, transaction),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}