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

  /// Ajoute plusieurs transactions en lot.
  Future<void> addBatch(List<Transaction> transactions) async {
    await _repository.saveTransactions(transactions);

    // Mise à jour des prix en lot
    // On ne garde que la dernière transaction (la plus récente) pour chaque ticker
    final Map<String, Transaction> latestTransactionsByTicker = {};
    
    for (var t in transactions) {
      if (t.assetTicker != null && t.price != null && t.type == TransactionType.Buy) {
        if (latestTransactionsByTicker.containsKey(t.assetTicker!)) {
           if (t.date.isAfter(latestTransactionsByTicker[t.assetTicker!]!.date)) {
             latestTransactionsByTicker[t.assetTicker!] = t;
           }
        } else {
           latestTransactionsByTicker[t.assetTicker!] = t;
        }
      }
    }

    for (var t in latestTransactionsByTicker.values) {
      await _updateAssetPrice(
        ticker: t.assetTicker!,
        price: t.price!,
        currency: t.priceCurrency ?? 'EUR',
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