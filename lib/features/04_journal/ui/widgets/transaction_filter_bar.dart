import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon_button.dart';
import 'package:portefeuille/features/04_journal/ui/models/transaction_sort_option.dart';

class TransactionFilterBar extends StatelessWidget {
  final TransactionSortOption sortOption;
  final ValueChanged<TransactionSortOption> onSortChanged;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeleteSelected;
  final VoidCallback onCancelSelection;
  final VoidCallback onAddTransaction;
  final VoidCallback onImportPdf;
  final VoidCallback onImportCsv;
  final VoidCallback onImportAi;
  final VoidCallback onImportCrowdfunding;

  const TransactionFilterBar({
    super.key,
    required this.sortOption,
    required this.onSortChanged,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onDeleteSelected,
    required this.onCancelSelection,
    required this.onAddTransaction,
    required this.onImportPdf,
    required this.onImportCsv,
    required this.onImportAi,
    required this.onImportCrowdfunding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  AppIconButton(
                    icon: Icons.add_circle,
                    color: AppColors.primary,
                    tooltip: 'Ajouter',
                    onPressed: onAddTransaction,
                  ),
                  AppIconButton(
                    icon: Icons.upload_file,
                    color: AppColors.primary,
                    tooltip: 'Import PDF',
                    onPressed: onImportPdf,
                  ),
                  AppIconButton(
                    icon: Icons.grid_on,
                    color: AppColors.primary,
                    tooltip: 'Import CSV (Revolut)',
                    onPressed: onImportCsv,
                  ),
                  AppIconButton(
                    icon: Icons.table_view,
                    color: AppColors.primary,
                    tooltip: 'Import Excel (Crowdfunding)',
                    onPressed: onImportCrowdfunding,
                  ),
                  AppIconButton(
                    icon: Icons.auto_awesome,
                    color: AppColors.primary,
                    tooltip: 'Import IA',
                    onPressed: onImportAi,
                  ),
                ],
              ),

              // Tri (Droite)
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
          ],
        ),
      ),
    );
  }
}


