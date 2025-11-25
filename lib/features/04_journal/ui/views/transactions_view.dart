import 'package:flutter/material.dart';
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
import 'package:portefeuille/features/09_imports/ui/screens/import_hub_screen.dart';
import 'package:portefeuille/features/00_app/services/institution_service.dart';
import 'package:portefeuille/core/data/models/institution_metadata.dart';

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
  TransactionSortOption _sortOption = TransactionSortOption.institution;
  final Set<String> _selectedIds = {};
  final InstitutionService _institutionService = InstitutionService();

  @override
  void initState() {
    super.initState();
    _institutionService.loadInstitutions().then((_) {
      if (mounted) setState(() {});
    });
  }

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
      Map<String, String> accountIdToInstitutionName,
      Map<String, String?> institutionNameToLogo,
  ) {
    final groups = <String, TransactionGroup>{};

    for (var transaction in transactions) {
      String key;
      String title;
      String? subtitle;
      String? logoPath;

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
          logoPath = institutionNameToLogo[institutionName];
          break;

        case TransactionSortOption.account:
          final account = accountsMap[transaction.accountId];
          final accountName = account?.name ?? 'Inconnu';
          final institutionName = accountIdToInstitutionName[transaction.accountId] ?? '';
          key = accountName;
          title = accountName;
          subtitle = institutionName;
          logoPath = institutionNameToLogo[institutionName];
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
          logoPath: logoPath,
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

  void _checkAndOpen(VoidCallback openMethod) {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    final hasAccounts = provider.activePortfolio?.institutions.any((i) => i.accounts.isNotEmpty) ?? false;

    if (!hasAccounts) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text("Aucun compte", style: AppTypography.h3),
          content: Text("Vous devez créer un compte avant d'importer des transactions.", style: AppTypography.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }
    openMethod();
  }

  void _openImportHub() => _checkAndOpen(() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ImportHubScreen(),
    );
  });

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
        final institutionNameToLogo = <String, String?>{};
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        
        // Build map of institution name to logo
        for (var inst in portfolio.institutions) {
           // Find metadata for this institution
           final metadataList = _institutionService.search(inst.name);
           // Exact match or first match? search returns contains.
           // Let's try to find exact match first
           InstitutionMetadata? meta;
           try {
             meta = metadataList.firstWhere((m) => m.name.toLowerCase() == inst.name.toLowerCase());
           } catch (_) {
             if (metadataList.isNotEmpty) meta = metadataList.first;
           }
           
           institutionNameToLogo[inst.name] = meta?.logoAsset;

          for (var acc in inst.accounts) {
            accountsMap[acc.id] = acc;
            accountIdToInstitutionName[acc.id] = inst.name;
          }
        }

        final List<Transaction> allTransactions = portfolio.institutions
            .expand((inst) => inst.accounts)
            .expand((acc) => acc.transactions)
            .toList();

        final groupedTransactions = _groupTransactions(allTransactions, accountsMap, accountIdToInstitutionName, institutionNameToLogo);
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
                  onImportHub: _openImportHub,
                ),
              ),

              const SizedBox(height: AppDimens.paddingM),

              Expanded(
                child: allTransactions.isEmpty
                    ? FadeInSlide(
                        delay: 0.2,
                        duration: 0.6,
                        child: EmptyTransactionsWidget(
                          onImportHub: _openImportHub,
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