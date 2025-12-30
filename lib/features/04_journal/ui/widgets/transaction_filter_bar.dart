import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/04_journal/ui/models/transaction_sort_option.dart';

class TransactionFilterBar extends StatelessWidget {
  final TransactionSortOption sortOption;
  final ValueChanged<TransactionSortOption> onSortChanged;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeleteSelected;
  final VoidCallback onCancelSelection;
  final VoidCallback onImportHub;
  final String? filterAccountId;
  final String? filterInstitutionName;
  final Map<String, Account> accounts;
  final List<String> institutions;
  final ValueChanged<String?> onFilterAccountChanged;
  final ValueChanged<String?> onFilterInstitutionChanged;
  final VoidCallback onClearFilters;

  const TransactionFilterBar({
    super.key,
    required this.sortOption,
    required this.onSortChanged,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onDeleteSelected,
    required this.onCancelSelection,
    required this.onImportHub,
    required this.filterAccountId,
    required this.filterInstitutionName,
    required this.accounts,
    required this.institutions,
    required this.onFilterAccountChanged,
    required this.onFilterInstitutionChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = filterAccountId != null || filterInstitutionName != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isSelectionMode) ...[
              Text('$selectedCount sélectionné(s)', style: AppTypography.bodyBold),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.select_all, color: AppColors.primary),
                    onPressed: onSelectAll,
                    tooltip: 'Tout sélectionner',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: onDeleteSelected,
                    tooltip: 'Supprimer la sélection',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancelSelection,
                    tooltip: 'Annuler',
                  ),
                ],
              ),
            ] else ...[
              // Actions (Gauche)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: onImportHub,
                    icon: const Icon(Icons.add, size: AppComponentSizes.iconSmall),
                    label: const Text("Ajouter / Importer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radius20),
                      ),
                    ),
                  ),
                ],
              ),

              // Tri (Droite)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton de filtrage
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.filter_list,
                      color: hasActiveFilter ? AppColors.success : AppColors.primary,
                    ),
                    tooltip: 'Filtrer',
                    onSelected: (value) {
                      if (value == 'clear') {
                        onClearFilters();
                      } else if (value.startsWith('account:')) {
                        final accountId = value.substring(8);
                        onFilterAccountChanged(accountId);
                      } else if (value.startsWith('institution:')) {
                        final instName = value.substring(12);
                        onFilterInstitutionChanged(instName);
                      }
                    },
                    itemBuilder: (context) => [
                      if (hasActiveFilter)
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.clear, size: AppComponentSizes.iconSmall, color: AppColors.error),
                              AppSpacing.gapHorizontalSmall,
                              Text('Effacer les filtres'),
                            ],
                          ),
                        ),
                      if (hasActiveFilter)
                        const PopupMenuDivider(),
                      const PopupMenuItem(
                        enabled: false,
                        child: Text('Par Institution', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...institutions.map((instName) => PopupMenuItem(
                        value: 'institution:$instName',
                        child: Text(instName),
                      )),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        enabled: false,
                        child: Text('Par Compte', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...accounts.entries.map((entry) => PopupMenuItem(
                        value: 'account:${entry.key}',
                        child: Text(entry.value.name),
                      )),
                    ],
                  ),
                  PopupMenuButton<TransactionSortOption>(
                    icon: const Icon(Icons.sort, color: AppColors.primary),
                    tooltip: 'Trier par',
                    initialValue: sortOption,
                    onSelected: onSortChanged,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: TransactionSortOption.dateDesc, child: Text('Date (Récent)')),
                      const PopupMenuItem(value: TransactionSortOption.dateAsc, child: Text('Date (Ancien)')),
                      const PopupMenuItem(value: TransactionSortOption.amountDesc, child: Text('Montant (Haut)')),
                      const PopupMenuItem(value: TransactionSortOption.amountAsc, child: Text('Montant (Bas)')),
                      const PopupMenuItem(value: TransactionSortOption.type, child: Text('Type')),
                      const PopupMenuItem(value: TransactionSortOption.institution, child: Text('Institution')),
                      const PopupMenuItem(value: TransactionSortOption.account, child: Text('Compte')),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
        // Chips pour afficher les filtres actifs
        if (hasActiveFilter)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM, vertical: 4),
            child: Row(
              children: [
                if (filterAccountId != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        'Compte: ${accounts[filterAccountId]?.name ?? "Inconnu"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: AppComponentSizes.iconXSmall),
                      onDeleted: onClearFilters,
                      backgroundColor: AppColors.success.withValues(alpha: AppOpacities.border),
                    ),
                  ),
                if (filterInstitutionName != null)
                  Chip(
                    label: Text(
                      'Institution: $filterInstitutionName',
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: AppComponentSizes.iconXSmall),
                    onDeleted: onClearFilters,
                    backgroundColor: AppColors.success.withValues(alpha: AppOpacities.border),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}


