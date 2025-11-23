import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:provider/provider.dart';

// Core UI
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';

// Data & Logic
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';
import 'package:portefeuille/features/07_management/ui/screens/edit_transaction_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_transaction_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/pdf_import_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/ai_import_config_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/crowdfunding_import_screen.dart';

// New Widgets & Models
import 'package:portefeuille/features/04_journal/ui/models/transaction_group.dart';
import 'package:portefeuille/features/04_journal/ui/models/transaction_sort_option.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/empty_transactions_widget.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/transaction_filter_bar.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/transaction_group_widget.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  TransactionSortOption _sortOption = TransactionSortOption.dateDesc;
  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Transaction> transactions) {
    setState(() {
      if (_selectedIds.length == transactions.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(transactions.map((t) => t.id));
      }
    });
  }

  Future<void> _deleteSelectedTransactions(TransactionProvider provider) async {
    final count = _selectedIds.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Supprimer $count transactions ?', style: AppTypography.h3),
        content: Text(
          'Cette action est irréversible.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Supprimer', style: AppTypography.label.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final idsToDelete = _selectedIds.toList();
      setState(() {
        _selectedIds.clear();
      });
      
      final futures = idsToDelete.map((id) => provider.deleteTransaction(id));
      await Future.wait(futures);
    }
  }

  Map<String, TransactionGroup> _groupTransactions(
      List<Transaction> transactions,
      Map<String, Account> accountsMap,
      Map<String, String> accountIdToInstitutionName
  ) {
    final groups = <String, TransactionGroup>{};

    for (var transaction in transactions) {
      String key;
      String title;
      String? subtitle;

      switch (_sortOption) {
        case TransactionSortOption.dateDesc:
        case TransactionSortOption.dateAsc:
          final now = DateTime.now();
          final date = transaction.date;
          final diff = now.difference(date).inDays;

          if (diff == 0) {
            key = 'Aujourd\'hui';
          } else if (diff == 1) {
            key = 'Hier';
          } else if (diff < 7) {
            key = 'Cette semaine';
          } else if (diff < 30) {
            key = 'Ce mois-ci';
          } else if (diff < 60) {
            key = 'Mois dernier';
          } else {
            key = 'Plus ancien';
          }
          title = key;
          break;

        case TransactionSortOption.institution:
          final institutionName = accountIdToInstitutionName[transaction.accountId] ?? 'Inconnu';
          key = institutionName;
          title = institutionName;
          break;

        case TransactionSortOption.account:
          final account = accountsMap[transaction.accountId];
          final accountName = account?.name ?? 'Inconnu';
          final institutionName = accountIdToInstitutionName[transaction.accountId] ?? '';
          key = accountName;
          title = accountName;
          subtitle = institutionName;
          break;

        case TransactionSortOption.type:
          key = transaction.type.displayName;
          title = key;
          break;

        default:
          key = 'Autres';
          title = 'Autres';
          break;
      }

      if (!groups.containsKey(key)) {
        groups[key] = TransactionGroup(
          title: title,
          subtitle: subtitle,
          transactions: [],
          totalAmount: 0,
        );
      }

      groups[key]!.transactions.add(transaction);
    }

    for (var group in groups.values) {
      group.transactions.sort((a, b) => b.date.compareTo(a.date));
    }

    return groups;
  }

  void _confirmDelete(BuildContext context, TransactionProvider provider, Transaction transaction) {
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

  void _openAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddTransactionScreen(),
    );
  }

  void _openPdfImport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PdfImportScreen()),
    );
  }

  void _openAiImport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiImportConfigScreen()),
    );
  }

  void _openCrowdfundingImport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrowdfundingImportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top + 90;

    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final portfolio = provider.activePortfolio;
        if (portfolio == null) {
          return const Center(child: Text("Aucun portefeuille."));
        }

        final accountsMap = <String, Account>{};
        final accountIdToInstitutionName = <String, String>{};
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        for (var inst in portfolio.institutions) {
          for (var acc in inst.accounts) {
            accountsMap[acc.id] = acc;
            accountIdToInstitutionName[acc.id] = inst.name;
          }
        }

        final List<Transaction> allTransactions = portfolio.institutions
            .expand((inst) => inst.accounts)
            .expand((acc) => acc.transactions)
            .toList();

        final groupedTransactions = _groupTransactions(allTransactions, accountsMap, accountIdToInstitutionName);
        final sortedGroupKeys = groupedTransactions.keys.toList();

        return AppScreen(
          withSafeArea: false,
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: topPadding, bottom: AppDimens.paddingL),
                child: Center(
                  child: FadeInSlide(
                    duration: 0.6,
                    child: Text('Transactions', style: AppTypography.h2),
                  ),
                ),
              ),

              FadeInSlide(
                delay: 0.1,
                duration: 0.6,
                child: TransactionFilterBar(
                  sortOption: _sortOption,
                  onSortChanged: (val) => setState(() => _sortOption = val),
                  isSelectionMode: _isSelectionMode,
                  selectedCount: _selectedIds.length,
                  onSelectAll: () => _selectAll(allTransactions),
                  onDeleteSelected: () => _deleteSelectedTransactions(transactionProvider),
                  onCancelSelection: () => setState(() => _selectedIds.clear()),
                  onAddTransaction: _openAddTransactionModal,
                  onImportPdf: _openPdfImport,
                  onImportAi: _openAiImport,
                  onImportCrowdfunding: _openCrowdfundingImport,
                ),
              ),

              const SizedBox(height: AppDimens.paddingM),

              Expanded(
                child: allTransactions.isEmpty
                    ? FadeInSlide(
                        delay: 0.2,
                        duration: 0.6,
                        child: EmptyTransactionsWidget(
                          onAdd: _openAddTransactionModal,
                          onImportPdf: _openPdfImport,
                          onImportCrowdfunding: _openCrowdfundingImport,
                          onImportAi: _openAiImport,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(AppDimens.paddingM, 0, AppDimens.paddingM, 80),
                        itemCount: sortedGroupKeys.length,
                        itemBuilder: (context, groupIndex) {
                          final key = sortedGroupKeys[groupIndex];
                          final group = groupedTransactions[key]!;
                          
                          return FadeInSlide(
                            delay: 0.2 + (groupIndex * 0.05), // Staggered animation
                            duration: 0.5,
                            child: TransactionGroupWidget(
                              group: group,
                              accountsMap: accountsMap,
                              selectedIds: _selectedIds,
                              isSelectionMode: _isSelectionMode,
                              onToggleSelection: _toggleSelection,
                              onDelete: (t) => _confirmDelete(context, transactionProvider, t),
                              onEdit: (t) => _editTransaction(context, t),
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