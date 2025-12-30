import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/core/Design_Center/widgets/components/app_tile.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final String accountName;
  final String accountCurrency;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.accountName,
    required this.accountCurrency,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _getTypeInfo(transaction.type);
    final isPositive = transaction.totalAmount >= 0;

    return AppTile(
      // 1. Icône colorée selon le type (Achat, Vente, etc.)
      leading: AppIcon(
        icon: typeInfo.icon,
        color: typeInfo.color,
        backgroundColor: typeInfo.color.withValues(alpha: AppOpacities.lightOverlay),
      ),

      // 2. Titre et sous-titre
      title: _getTitle(transaction),
      subtitle: _getSubtitle(transaction),

      // 3. Montant et Date
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                CurrencyFormatter.format(transaction.totalAmount, accountCurrency),
                style: AppTypography.bodyBold.copyWith(
                  color: isPositive ? AppColors.success : AppColors.textPrimary,
                ),
              ),
              Text(
                DateFormat('dd/MM/yy').format(transaction.date),
                style: AppTypography.caption,
              ),
            ],
          ),
          AppSpacing.gapS,

          // 4. Menu contextuel (Edit/Delete)
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: AppColors.surfaceLight, // Fond du menu popup
              iconTheme: const IconThemeData(color: AppColors.textSecondary),
            ),
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: AppComponentSizes.iconSmall),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: AppComponentSizes.iconSmall),
                      AppSpacing.gapH12,
                      Text('Modifier', style: AppTypography.body),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: AppComponentSizes.iconSmall, color: AppColors.error),
                      AppSpacing.gapH12,
                      Text('Supprimer', style: AppTypography.body.copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helpers pour le style
  ({IconData icon, Color color}) _getTypeInfo(TransactionType type) {
    switch (type) {
      case TransactionType.Buy:
        return (icon: Icons.shopping_cart_outlined, color: AppColors.primary); // Bleu
      case TransactionType.Sell:
        return (icon: Icons.sell_outlined, color: AppColors.accent); // Violet
      case TransactionType.Dividend:
        return (icon: Icons.card_giftcard, color: AppColors.success); // Vert
      case TransactionType.Deposit:
        return (icon: Icons.arrow_downward, color: AppColors.success); // Vert
      case TransactionType.Withdrawal:
        return (icon: Icons.arrow_upward, color: AppColors.textSecondary); // Gris
      case TransactionType.Fees:
        return (icon: Icons.receipt_long_outlined, color: AppColors.warning); // Orange
      case TransactionType.Interest:
        return (icon: Icons.percent, color: AppColors.success); // Vert
      // case TransactionType.InterestPayment: // SUPPRIMÉ
      //   return (icon: Icons.savings_outlined, color: AppColors.success); // Vert
      case TransactionType.CapitalRepayment:
        return (icon: Icons.account_balance_wallet_outlined, color: AppColors.primary); // Bleu
      case TransactionType.EarlyRepayment:
        return (icon: Icons.flash_on_outlined, color: AppColors.primary); // Bleu
    }
  }

  String _getTitle(Transaction tr) {
    switch (tr.type) {
      case TransactionType.Buy:      return "Achat ${tr.assetTicker}";
      case TransactionType.Sell:     return "Vente ${tr.assetTicker}";
      case TransactionType.Dividend: return "Dividende ${tr.assetTicker}";
      case TransactionType.Deposit:  return "Dépôt";
      case TransactionType.Withdrawal: return "Retrait";
      case TransactionType.Interest: return "Intérêts";
      case TransactionType.Fees:     return "Frais";
      // case TransactionType.InterestPayment: return "Intérêts (Crowdfunding)"; // SUPPRIMÉ
      case TransactionType.CapitalRepayment: return "Remboursement Capital";
      case TransactionType.EarlyRepayment: return "Remboursement Anticipé";
    }
  }

  String _getSubtitle(Transaction tr) {
    if (tr.type == TransactionType.Buy || tr.type == TransactionType.Sell) {
      final qty = tr.quantity?.toStringAsFixed(4) ?? '0';
      final price = (tr.price != null) ? tr.price!.toStringAsFixed(2) : '0';
      return "$qty x $price";
    }
    return tr.notes.isNotEmpty ? tr.notes : accountName;
  }
}