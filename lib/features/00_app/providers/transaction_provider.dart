import 'package:flutter/foundation.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService;
  final PortfolioProvider _portfolioProvider;

  TransactionProvider({
    required TransactionService transactionService,
    required PortfolioProvider portfolioProvider,
  })  : _transactionService = transactionService,
        _portfolioProvider = portfolioProvider;

  Future<void> addTransaction(Transaction transaction) async {
    debugPrint("🔄 [TransactionProvider] addTransaction");
    await _transactionService.add(transaction);
    await _portfolioProvider.refreshData();
  }

  Future<void> addTransactions(List<Transaction> transactions) async {
    debugPrint("🔄 [TransactionProvider] addTransactions (${transactions.length})");
    await _transactionService.addBatch(transactions);
    await _portfolioProvider.refreshData();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    debugPrint("🔄 [TransactionProvider] updateTransaction");
    await _transactionService.update(transaction);
    await _portfolioProvider.refreshData();
  }

  Future<void> deleteTransaction(String transactionId) async {
    debugPrint("🔄 [TransactionProvider] deleteTransaction");
    await _transactionService.delete(transactionId);
    await _portfolioProvider.refreshData();
  }
}
