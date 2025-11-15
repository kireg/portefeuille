// lib/features/04_journal/ui/views/transactions_view.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/transaction_list_item.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/07_management/ui/screens/edit_transaction_screen.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

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

  void _confirmDelete(BuildContext context, PortfolioProvider provider,
      Transaction transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la transaction ?'),
        content: const Text(
            'Cette action est irréversible et affectera le calcul de vos soldes et performances.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              provider.deleteTransaction(transaction.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _editTransaction(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditTransactionScreen(
        existingTransaction: transaction,
      ),
    );
  }

  List<Transaction> _sortTransactions(List<Transaction> transactions) {
    switch (_sortOption) {
      case TransactionSortOption.dateAsc:
        transactions.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TransactionSortOption.amountDesc:
        transactions.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case TransactionSortOption.amountAsc:
        transactions.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case TransactionSortOption.type:
        transactions.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;
      case TransactionSortOption.dateDesc:
        transactions.sort((a, b) => b.date.compareTo(a.date));
        break;
    }
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final portfolio = provider.activePortfolio;
        if (portfolio == null) {
          return const Center(child: Text("Aucun portefeuille."));
        }

        final accountNames = <String, String>{};
        for (var inst in portfolio.institutions) {
          for (var acc in inst.accounts) {
            accountNames[acc.id] = acc.name;
          }
        }

        final List<Transaction> allTransactions = portfolio.institutions
            .expand((inst) => inst.accounts)
            .expand((acc) => acc.transactions)
            .toList();

        final sortedTransactions = _sortTransactions(allTransactions);

        if (allTransactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppTheme.buildEmptyStateCard(
              context: context,
              icon: Icons.receipt_long_outlined,
              title: 'Aucune transaction',
              subtitle:
              'Utilisez le bouton "+" en bas de l\'écran pour ajouter votre première transaction.',
              buttonLabel: 'Ajouter une transaction',
              onPressed: () {
                // Navigation vers l'ajout de transaction
                // Adapter selon votre navigation
              },
            ),
          );
        }

        return Column(
          children: [
            // Barre de tri
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppTheme.buildStyledCard(
                context: context,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Trier par :', style: theme.textTheme.bodyMedium),
                    DropdownButton<TransactionSortOption>(
                      value: _sortOption,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: TransactionSortOption.dateDesc,
                          child: Text('Date (Récent)'),
                        ),
                        DropdownMenuItem(
                          value: TransactionSortOption.dateAsc,
                          child: Text('Date (Ancien)'),
                        ),
                        DropdownMenuItem(
                          value: TransactionSortOption.amountDesc,
                          child: Text('Montant (Élevé)'),
                        ),
                        DropdownMenuItem(
                          value: TransactionSortOption.amountAsc,
                          child: Text('Montant (Faible)'),
                        ),
                        DropdownMenuItem(
                          value: TransactionSortOption.type,
                          child: Text('Type'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortOption = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Liste des transactions
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 80.0,
                ),
                itemCount: sortedTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = sortedTransactions[index];
                  final accountName =
                      accountNames[transaction.accountId] ?? 'Compte inconnu';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TransactionListItem(
                      transaction: transaction,
                      accountName: accountName,
                      onDelete: () =>
                          _confirmDelete(context, provider, transaction),
                      onEdit: () => _editTransaction(context, transaction),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}