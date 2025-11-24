import 'package:portefeuille/core/data/models/transaction.dart';

class TransactionGroup {
  final String title;
  final String? subtitle;
  final String? logoPath;
  final List<Transaction> transactions;
  final double totalAmount;

  TransactionGroup({
    required this.title,
    this.subtitle,
    this.logoPath,
    required this.transactions,
    required this.totalAmount,
  });
}
