// lib/features/00_app/providers/portfolio_transaction_logic.dart
// NOUVEAU FICHIER

import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';

class PortfolioTransactionLogic {
  final PortfolioRepository repository;

  PortfolioTransactionLogic({required this.repository});

  /// Ajoute une transaction et recharge les données.
  Future<void> addTransaction(Transaction transaction) async {
    await repository.saveTransaction(transaction);

    if (transaction.type == TransactionType.Buy &&
        transaction.assetTicker != null &&
        transaction.price != null) {

      final metadata = repository.getOrCreateAssetMetadata(transaction.assetTicker!);
      metadata.updatePrice(transaction.price!);
      await repository.saveAssetMetadata(metadata);
    }
  }

  /// Supprime une transaction et recharge les données.
  Future<void> deleteTransaction(String transactionId) async {
    await repository.deleteTransaction(transactionId);
  }

  /// Met à jour une transaction existante et recharge les données.
  Future<void> updateTransaction(Transaction transaction) async {
    await repository.saveTransaction(transaction);
    // La logique de mise à jour du prix lors de l'édition
    // peut être ajoutée ici si nécessaire.
  }
}