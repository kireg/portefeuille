// lib\features\04_journal\ui\views\transactions_view.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/transaction_list_item.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/07_management/ui/screens/edit_transaction_screen.dart';

// Enum pour les options de tri
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

  /// Affiche une confirmation avant de supprimer
  void _confirmDelete(BuildContext context, PortfolioProvider provider,
      Transaction transaction) {
    // ... (code de _confirmDelete inchangé)
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

  /// Ouvre l'écran de modification
  void _editTransaction(BuildContext context, Transaction transaction) {
    // ... (code de _editTransaction inchangé)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditTransactionScreen(
        existingTransaction: transaction,
      ),
    );
  }

  /// Logique de tri
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
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final portfolio = provider.activePortfolio;
        if (portfolio == null) {
          return const Center(child: Text("Aucun portefeuille."));
        }

        // 1. Map des noms de comptes (inchangé)
        final accountNames = <String, String>{};
        for (var inst in portfolio.institutions) {
          for (var acc in inst.accounts) {
            accountNames[acc.id] = acc.name;
          }
        }

        // 2. Agrégation (inchangé)
        final List<Transaction> allTransactions = portfolio.institutions
            .expand((inst) => inst.accounts)
            .expand((acc) => acc.transactions)
            .toList();

        // 3. Tri (MODIFIÉ)
        final sortedTransactions = _sortTransactions(allTransactions);

        if (allTransactions.isEmpty) {
          // ... (code "Aucune transaction" inchangé)
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune transaction',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Utilisez le bouton "+" en bas de l\'écran pour ajouter votre première transaction.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // 4. Construire la vue (ajout du Row de tri)
        return Column(
          children: [
            // --- NOUVEAU : Barre de tri ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Trier par :"),
                  DropdownButton<TransactionSortOption>(
                    value: _sortOption,
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
            // --- FIN NOUVEAU ---

            // --- NOUVEAU : Liste dans un Expanded ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  bottom: 80.0, // Espace pour le FAB
                ),
                itemCount: sortedTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = sortedTransactions[index];
                  final accountName =
                      accountNames[transaction.accountId] ?? 'Compte inconnu';

                  return TransactionListItem(
                    transaction: transaction,
                    accountName: accountName,
                    onDelete: () =>
                        _confirmDelete(context, provider, transaction),
                    onEdit: () => _editTransaction(context, transaction),
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