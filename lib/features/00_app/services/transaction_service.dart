// lib/features/00_app/services/transaction_service.dart

import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';

class TransactionService {
  final PortfolioRepository _repository;

  TransactionService({
    required PortfolioRepository repository,
  }) : _repository = repository;

  /// Ajoute une transaction.
  Future<void> add(Transaction transaction) async {
    await _repository.saveTransaction(transaction);

    // Si c'est un achat, met à jour le prix de l'actif
    if (transaction.type == TransactionType.Buy &&
        transaction.assetTicker != null &&
        transaction.price != null) {
      await _updateAssetPrice(
        ticker: transaction.assetTicker!,
        price: transaction.price!,
        currency: transaction.priceCurrency ?? 'EUR',
      );
    }
  }

  /// Supprime une transaction.
  Future<void> delete(String transactionId) async {
    await _repository.deleteTransaction(transactionId);
  }

  /// Met à jour une transaction existante.
  Future<void> update(Transaction transaction) async {
    await _repository.saveTransaction(transaction);

    // Mettre à jour le prix pour les achats ET les ventes
    if ((transaction.type == TransactionType.Buy ||
        transaction.type == TransactionType.Sell) &&
        transaction.assetTicker != null &&
        transaction.price != null) {
      await _updateAssetPrice(
        ticker: transaction.assetTicker!,
        price: transaction.price!,
        currency: transaction.priceCurrency ?? 'EUR',
      );
    }
  }

  Future<void> _updateAssetPrice({
    required String ticker,
    required double price,
    required String currency,
  }) async {
    final metadata = _repository.getOrCreateAssetMetadata(ticker);
    metadata.updatePrice(price, currency);
    await _repository.saveAssetMetadata(metadata);
  }
}