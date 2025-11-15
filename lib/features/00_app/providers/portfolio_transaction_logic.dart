// lib/features/00_app/providers/portfolio_transaction_logic.dart
// REMPLACEZ LE FICHIER COMPLET

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

    // Si c'est un achat, met à jour le prix de l'actif
    if (transaction.type == TransactionType.Buy &&
        transaction.assetTicker != null &&
        transaction.price != null) {
      final metadata =
      repository.getOrCreateAssetMetadata(transaction.assetTicker!);

      // --- CORRECTION DE L'ERREUR ---
      // La devise est DANS la transaction que nous venons de créer
      final currency = transaction.priceCurrency ?? 'EUR'; // Fallback sur EUR
      metadata.updatePrice(transaction.price!, currency);
      // --- FIN CORRECTION ---

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
    // (Optionnel) Mettre aussi à jour le prix des métadonnées lors de l'édition
    if ((transaction.type == TransactionType.Buy ||
        transaction.type == TransactionType.Sell) &&
        transaction.assetTicker != null &&
        transaction.price != null) {
      final metadata =
      repository.getOrCreateAssetMetadata(transaction.assetTicker!);
      final currency = transaction.priceCurrency ?? 'EUR';
      metadata.updatePrice(transaction.price!, currency);
      await repository.saveAssetMetadata(metadata);
    }
  }
}