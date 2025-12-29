import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';
import 'package:portefeuille/features/09_imports/ui/widgets/transaction_edit_dialog.dart';

/// Widget affichant une transaction candidate à l'import.
/// 
/// Affiche les informations de la transaction avec :
/// - Case à cocher de sélection
/// - Icône de direction (achat/vente)
/// - Nom, date, type
/// - Badge "Modifié" si applicable
/// - Montant et quantité
/// - Menu contextuel (éditer, supprimer)
class WizardCandidateCard extends StatelessWidget {
  final ImportCandidate candidate;
  final ValueChanged<bool> onSelectionChanged;
  final ValueChanged<ParsedTransaction> onEdit;
  final VoidCallback onDelete;

  const WizardCandidateCard({
    super.key,
    required this.candidate,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tx = candidate.parsed;
    final isInflow = tx.type == TransactionType.Buy ||
        tx.type == TransactionType.Deposit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildCheckbox(),
            _buildDirectionIcon(isInflow),
            const SizedBox(width: 12),
            Expanded(child: _buildTransactionInfo(tx)),
            _buildAmountInfo(tx),
            _buildPopupMenu(context, tx),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return Checkbox(
      value: candidate.selected,
      onChanged: (val) => onSelectionChanged(val ?? false),
    );
  }

  Widget _buildDirectionIcon(bool isInflow) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isInflow
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isInflow ? Icons.arrow_downward : Icons.arrow_upward,
        color: isInflow ? AppColors.success : AppColors.error,
        size: 16,
      ),
    );
  }

  Widget _buildTransactionInfo(ParsedTransaction tx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tx.assetName,
                style: AppTypography.bodyBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (candidate.isModified) _buildModifiedBadge(),
          ],
        ),
        Text(
          "${tx.date.day}/${tx.date.month}/${tx.date.year} • "
          "${tx.type.toString().split('.').last}",
          style: AppTypography.caption,
        ),
        if (tx.isin != null)
          Text(
            "ISIN: ${tx.isin}",
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildModifiedBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Modifié",
        style: AppTypography.caption.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAmountInfo(ParsedTransaction tx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "${tx.amount.toStringAsFixed(2)} ${tx.currency}",
          style: AppTypography.bodyBold,
        ),
        Text(
          "${tx.quantity} @ ${tx.price.toStringAsFixed(2)}",
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context, ParsedTransaction tx) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      onSelected: (value) {
        if (value == 'edit') {
          showDialog(
            context: context,
            builder: (context) => TransactionEditDialog(
              transaction: tx,
              onSave: onEdit,
            ),
          );
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text("Modifier"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text("Supprimer", style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}
