import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';
import 'package:portefeuille/core/utils/isin_validator.dart';

class PdfTransactionList extends StatelessWidget {
  final List<ParsedTransaction> transactions;
  final List<Transaction> existingTransactions;
  final Function(int) onEdit;
  final Function(int) onRemove;
  final bool isLoading;

  const PdfTransactionList({
    super.key,
    required this.transactions,
    required this.existingTransactions,
    required this.onEdit,
    required this.onRemove,
    required this.isLoading,
  });

  bool _isDuplicate(ParsedTransaction parsed) {
    for (final existing in existingTransactions) {
      final sameDate = existing.date.year == parsed.date.year && 
                       existing.date.month == parsed.date.month && 
                       existing.date.day == parsed.date.day;
      
      if (!sameDate) continue;
      
      final sameType = existing.type == parsed.type;
      if (!sameType) continue;

      final sameQuantity = (existing.quantity ?? 0) == parsed.quantity;
      if (!sameQuantity) continue;

      // Check asset identity
      bool sameAsset = false;
      if (parsed.isin != null && existing.assetTicker == parsed.isin) {
        sameAsset = true;
      } else if (parsed.ticker != null && existing.assetTicker == parsed.ticker) {
        sameAsset = true;
      } else if (existing.assetName == parsed.assetName) {
        sameAsset = true;
      }

      if (sameAsset) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text("Analyse du PDF en cours...", style: AppTypography.body),
          ],
        ),
      );
    }

    if (transactions.isNotEmpty) {
      return Column(
        children: transactions.asMap().entries.map((entry) {
          final index = entry.key;
          final tx = entry.value;
          final isDuplicate = _isDuplicate(tx);
          final hasTicker = tx.ticker != null && tx.ticker!.isNotEmpty;
          final hasIsin = tx.isin != null && IsinValidator.isValidIsinFormat(tx.isin!);
          final isReady = (hasTicker || hasIsin) && tx.assetName.isNotEmpty;

          return FadeInSlide(
            delay: 0.2 + (index * 0.05),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
              child: Dismissible(
                key: ValueKey("${tx.date}_${tx.assetName}_$index"),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => onRemove(index),
                background: Container(
                  color: AppColors.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: AppCard(
                  backgroundColor: isDuplicate 
                      ? AppColors.warning.withOpacity(0.1) 
                      : (!isReady ? AppColors.error.withOpacity(0.05) : null),
                  onTap: () => onEdit(index),
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(child: Text(tx.assetName, style: AppTypography.bodyBold)),
                        if (isDuplicate)
                          const Tooltip(
                            message: "Cette transaction existe déjà",
                            child: Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                          ),
                        if (!isReady && !isDuplicate)
                          const Tooltip(
                            message: "Informations manquantes (ISIN/Ticker)",
                            child: Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${tx.quantity} x ${tx.price} ${tx.currency} = ${tx.amount} ${tx.currency}",
                          style: AppTypography.caption,
                        ),
                        if (tx.isin != null)
                          Text("ISIN: ${tx.isin}", style: AppTypography.caption.copyWith(fontSize: 10)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tx.type.toString().split('.').last.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: tx.type.toString().contains('Buy') ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }
}
