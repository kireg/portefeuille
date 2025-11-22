import 'package:portefeuille/core/data/models/transaction.dart';

class TransactionGroup {
  final String title;
  final String? subtitle;
  final List<Transaction> transactions;
  final double totalAmount;

  TransactionGroup({
    required this.title,
    this.subtitle,
    required this.transactions,
    required this.totalAmount,
  });
}
