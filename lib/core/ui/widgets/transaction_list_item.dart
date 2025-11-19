// lib/core/ui/widgets/transaction_list_item.dart
// Centralized TransactionListItem widget moved from features/04_journal/ui/widgets

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
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

  IconData _getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.Deposit:
        return Icons.input;
      case TransactionType.Withdrawal:
        return Icons.output;
      case TransactionType.Buy:
        return Icons.shopping_cart_checkout;
      case TransactionType.Sell:
        return Icons.sell_outlined;
      case TransactionType.Dividend:
        return Icons.paid_outlined;
      case TransactionType.Interest:
        return Icons.percent_outlined;
      case TransactionType.Fees:
        return Icons.receipt_long_outlined;
    }
  }

  String _getTitle(Transaction tr) {
    switch (tr.type) {
      case TransactionType.Buy:
        return "Achat ${tr.assetName ?? tr.assetTicker}";
      case TransactionType.Sell:
        return "Vente ${tr.assetName ?? tr.assetTicker}";
      case TransactionType.Dividend:
        return "Dividende ${tr.assetName ?? tr.assetTicker}";
      case TransactionType.Deposit:
        return "Dépôt de liquidités";
      case TransactionType.Withdrawal:
        return "Retrait de liquidités";
      case TransactionType.Interest:
        return "Intérêts perçus";
      case TransactionType.Fees:
        return "Frais divers";
    }
  }

  String _getSubtitle(Transaction tr) {
    if (tr.type == TransactionType.Buy || tr.type == TransactionType.Sell) {
      final qty = tr.quantity?.toStringAsFixed(4) ?? 'N/A';
      final priceCurrency = tr.priceCurrency ?? accountCurrency;
      final price = (tr.price != null)
          ? CurrencyFormatter.format(tr.price!, priceCurrency)
          : 'N/A';
      return "$qty @ $price";
    }
    return tr.notes.isNotEmpty ? tr.notes : accountName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _getTitle(transaction);
    final subtitle = _getSubtitle(transaction);
    final icon = _getIconForType(transaction.type);

    final totalAmount = transaction.totalAmount;
    final color =
        totalAmount >= 0 ? Colors.green.shade400 : theme.colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(totalAmount, accountCurrency),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(transaction.date),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: onEdit,
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: onDelete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 20, color: theme.colorScheme.error),
                        SizedBox(width: 8),
                        Text('Supprimer',
                            style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

