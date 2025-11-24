import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/transaction_list_item.dart';
import 'package:portefeuille/features/04_journal/ui/models/transaction_group.dart';

class TransactionGroupWidget extends StatelessWidget {
  final TransactionGroup group;
  final Map<String, Account> accountsMap;
  final Set<String> selectedIds;
  final bool isSelectionMode;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<Transaction> onDelete;
  final ValueChanged<Transaction> onEdit;

  const TransactionGroupWidget({
    super.key,
    required this.group,
    required this.accountsMap,
    required this.selectedIds,
    required this.isSelectionMode,
    required this.onToggleSelection,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            leading: group.logoPath != null
                ? Image.asset(group.logoPath!, width: 32, height: 32)
                : null,
            title: Text(
              group.title,
              style: AppTypography.h3.copyWith(fontSize: 18),
            ),
            subtitle: group.subtitle != null ? Text(group.subtitle!, style: AppTypography.body) : null,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${group.transactions.length}',
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
            ),
            children: group.transactions.map((transaction) {
              final account = accountsMap[transaction.accountId];
              final accountName = account?.name ?? 'Inconnu';
              final accountCurrency = account?.activeCurrency ?? 'EUR';
              final isSelected = selectedIds.contains(transaction.id);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingS, vertical: 4),
                child: GestureDetector(
                  onLongPress: () => onToggleSelection(transaction.id),
                  onTap: isSelectionMode ? () => onToggleSelection(transaction.id) : null,
                  child: Stack(
                    children: [
                      TransactionListItem(
                        transaction: transaction,
                        accountName: accountName,
                        accountCurrency: accountCurrency,
                        onDelete: () => onDelete(transaction),
                        onEdit: () => onEdit(transaction),
                      ),
                      if (isSelectionMode)
                        Positioned.fill(
                          child: Container(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 8),
                            child: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.primary)
                                : const Icon(Icons.radio_button_unchecked, color: AppColors.textTertiary),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
