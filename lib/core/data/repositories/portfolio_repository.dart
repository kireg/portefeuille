// lib/core/data/repositories/portfolio_repository.dart
// VERSION NETTOYÉE ET CORRIGÉE

import 'package:hive/hive.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
// ... (autres imports)
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';
import 'package:portefeuille/core/data/models/exchange_rate_history.dart';
import 'package:portefeuille/core/data/models/price_history_point.dart';
import 'package:portefeuille/core/utils/constants.dart';
import 'package:uuid/uuid.dart';
// Assurez-vous que l'import d'Account est présent
// import 'package:portefeuille/core/data/models/account.dart';

/// Classe responsable de la gestion des données du portefeuille.
/// Elle abstrait la source de données (Hive) du reste de l'application.
class PortfolioRepository {
  late final Box<Portfolio> _portfolioBox =
  Hive.box(AppConstants.kPortfolioBoxName);

  late final Box<Transaction> _transactionBox =
  Hive.box(AppConstants.kTransactionBoxName);
  late final Box<AssetMetadata> _assetMetadataBox =
  Hive.box(AppConstants.kAssetMetadataBoxName);

  late final Box<SyncLog> _syncLogsBox =
  Hive.box(AppConstants.kSyncLogsBoxName);
  late final Box<ExchangeRateHistory> _exchangeRateHistoryBox =
  Hive.box(AppConstants.kExchangeRateHistoryBoxName);
  late final Box<PriceHistoryPoint> _priceHistoryBox =
  Hive.box(AppConstants.kPriceHistoryBoxName);

  final _uuid = const Uuid();

  /// Charge TOUS les portefeuilles depuis la source de données.
  /// MODIFIÉ : Injecte les transactions ET génère les actifs.
  List<Portfolio> getAllPortfolios() {
    final portfolios = _portfolioBox.values.toList();
    final allTransactions = getAllTransactions();

    // Créer un dictionnaire pour un accès rapide : { accountId: [Liste de Tx] }
    final transactionsByAccount = <String, List<Transaction>>{};
    for (final tx in allTransactions) {
      (transactionsByAccount[tx.accountId] ??= []).add(tx);
    }

    // "Hydrater" les portefeuilles : injecter les transactions et générer les actifs
    for (final portfolio in portfolios) {
      for (final institution in portfolio.institutions) {
        for (final account in institution.accounts) {

          final accountTransactions = transactionsByAccount[account.id] ?? [];

          // 1. Injecter les transactions
          account.transactions = accountTransactions;

          // -----------------------------------------------------------------
          // ▼▼▼ CORRECTION : GÉNÉRER ET ASSIGNER LES ASSETS ▼▼▼
          // -----------------------------------------------------------------
          // Appelle la méthode statique pour créer les assets "stupides"
          // et les assigne au champ 'assets' du compte.
          account.assets =
              Account.generateAssetsFromTransactions(accountTransactions);
          // -----------------------------------------------------------------
          // ▲▲▲ FIN CORRECTION ▲▲▲
          // -----------------------------------------------------------------
        }
      }
    }

    return portfolios;
  }

  /// Sauvegarde un portefeuille dans la source de données en utilisant son ID.
  Future<void> savePortfolio(Portfolio portfolio) async {
    await _portfolioBox.put(portfolio.id, portfolio);
  }

  /// Supprime un portefeuille spécifique.
  Future<void> deletePortfolio(String portfolioId) async {
    await _portfolioBox.delete(portfolioId);
  }

  /// Efface TOUTES les données (portefeuilles ET transactions).
  Future<void> deleteAllData() async {
    await _portfolioBox.clear();
    await _transactionBox.clear();
    await _assetMetadataBox.clear();
    await _syncLogsBox.clear();
    await _exchangeRateHistoryBox.clear();
    await _priceHistoryBox.clear();
  }

  /// Crée un nouveau portefeuille vide et le sauvegarde.
  Portfolio createEmptyPortfolio(String name) {
    final portfolio = Portfolio(
      id: _uuid.v4(),
      name: name,
      institutions: [],
    );
    savePortfolio(portfolio);
    return portfolio;
  }

  // --- GESTION DES TRANSACTIONS ---

  /// Charge TOUTES les transactions de la Box.
  List<Transaction> getAllTransactions() {
    return _transactionBox.values.toList();
  }

  /// Sauvegarde (ajoute ou met à jour) une transaction.
  Future<void> saveTransaction(Transaction transaction) async {
    await _transactionBox.put(transaction.id, transaction);
  }

  /// Sauvegarde plusieurs transactions en une seule opération (Batch).
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final Map<String, Transaction> entries = {
      for (var t in transactions) t.id: t
    };
    await _transactionBox.putAll(entries);
  }

  /// Supprime une transaction par son ID.
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionBox.delete(transactionId);
  }

  // --- MÉTHODES POUR LES MÉTADONNÉES D'ACTIFS ---

  AssetMetadata? getAssetMetadata(String ticker) {
    return _assetMetadataBox.get(ticker);
  }

  AssetMetadata getOrCreateAssetMetadata(String ticker) {
    final existing = _assetMetadataBox.get(ticker);
    if (existing != null) return existing;
    final newMetadata = AssetMetadata(ticker: ticker);
    saveAssetMetadata(newMetadata);
    return newMetadata;
  }

  Future<void> saveAssetMetadata(AssetMetadata metadata) async {
    await _assetMetadataBox.put(metadata.ticker, metadata);
  }

  Map<String, AssetMetadata> getAllAssetMetadata() {
    final metadata = Map.fromEntries(
      _assetMetadataBox.values.map((m) => MapEntry(m.ticker, m)),
    );
    return metadata;
  }

  // --- GESTION DE L'HISTORIQUE DES TAUX (1.2) ---

  Future<void> saveExchangeRate(ExchangeRateHistory rateHistory) async {
    final key =
        '${rateHistory.pair}_${rateHistory.date.toIso8601String().substring(0, 10)}';
    await _exchangeRateHistoryBox.put(key, rateHistory);
  }

  List<ExchangeRateHistory> getAllExchangeRates() {
    return _exchangeRateHistoryBox.values.toList();
  }

  // --- GESTION DE L'HISTORIQUE DES PRIX (2.1) ---

  Future<void> savePriceHistoryPoint(PriceHistoryPoint pricePoint) async {
    final key =
        '${pricePoint.ticker}_${pricePoint.date.toIso8601String().substring(0, 10)}';
    await _priceHistoryBox.put(key, pricePoint);
  }

  List<PriceHistoryPoint> getAllPriceHistory() {
    return _priceHistoryBox.values.toList();
  }

  // --- LES MÉTHODES createDemoPortfolio ET _getDemoData ONT ÉTÉ SUPPRIMÉES ---

  // --- GESTION DES LOGS DE SYNCHRONISATION (Inchangé) ---
  Future<void> addSyncLog(SyncLog log) async {
    await _syncLogsBox.add(log);
    await _rotateSyncLogs();
  }

  List<SyncLog> getAllSyncLogs() {
    final logs = _syncLogsBox.values.toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  List<SyncLog> getRecentSyncLogs({int limit = 100}) {
    final allLogs = getAllSyncLogs();
    return allLogs.take(limit).toList();
  }

  Future<void> clearAllSyncLogs() async {
    await _syncLogsBox.clear();
  }

  Future<void> _rotateSyncLogs() async {
    const maxLogs = 1000;
    if (_syncLogsBox.length > maxLogs) {
      final logs = getAllSyncLogs();
      final toDelete = logs.skip(maxLogs).toList();
      for (final log in toDelete) {
        final key = _syncLogsBox.keys.firstWhere(
              (k) => _syncLogsBox.get(k) == log,
          orElse: () => null,
        );
        if (key != null) {
          await _syncLogsBox.delete(key);
        }
      }
    }
  }
}