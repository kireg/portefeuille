// lib/core/data/repositories/portfolio_repository.dart

import 'package:hive/hive.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/utils/constants.dart';
import 'package:uuid/uuid.dart';

// --- NOUVEAUX IMPORTS ---
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
// --- FIN NOUVEAUX IMPORTS ---

/// Classe responsable de la gestion des données du portefeuille.
/// Elle abstrait la source de données (Hive) du reste de l'application.
class PortfolioRepository {
  late final Box<Portfolio> _portfolioBox =
  Hive.box(AppConstants.kPortfolioBoxName);

  // NOUVEAU : Box pour les transactions
  late final Box<Transaction> _transactionBox =
  Hive.box(AppConstants.kTransactionBoxName);
  
  // NOUVEAU : Box pour les métadonnées des actifs
  late final Box<AssetMetadata> _assetMetadataBox =
  Hive.box(AppConstants.kAssetMetadataBoxName);

  final _uuid = const Uuid();

  /// Charge TOUS les portefeuilles depuis la source de données.
  /// MODIFIÉ : Cette méthode injecte maintenant les transactions dans les comptes.
  List<Portfolio> getAllPortfolios() {
    final portfolios = _portfolioBox.values.toList();
    final allTransactions = getAllTransactions();
    final allMetadata = getAllAssetMetadata();

    // Créer un dictionnaire pour un accès rapide : { accountId: [Liste de Tx] }
    final transactionsByAccount = <String, List<Transaction>>{};
    for (final tx in allTransactions) {
      (transactionsByAccount[tx.accountId] ??= []).add(tx);
    }

    // "Hydrater" les portefeuilles : injecter les transactions dans chaque compte
    for (final portfolio in portfolios) {
      for (final institution in portfolio.institutions) {
        for (final account in institution.accounts) {
          account.transactions = transactionsByAccount[account.id] ?? [];
          
          // Vider le cache pour forcer la régénération des assets
          account.clearAssetsCache();
          
          // IMPORTANT: Récupérer les assets APRÈS avoir injecté les transactions
          // car le getter assets dépend des transactions
          final assets = account.assets;
          
          // Injecter les métadonnées dans les assets
          for (final asset in assets) {
            final metadata = allMetadata[asset.ticker];
            if (metadata != null) {
              asset.currentPrice = metadata.currentPrice;
              asset.estimatedAnnualYield = metadata.estimatedAnnualYield;
            }
          }
          
          // Mettre en cache les assets avec métadonnées injectées
          account.refreshAssetsCache(assets);
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
    // Note : La suppression des transactions orphelines
    // sera gérée par le PortfolioProvider
  }

  /// Efface TOUTES les données (portefeuilles ET transactions).
  Future<void> deleteAllData() async {
    await _portfolioBox.clear();
    await _transactionBox.clear(); // MODIFIÉ
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

  // --- NOUVELLES MÉTHODES DE GESTION DES TRANSACTIONS ---

  /// Charge TOUTES les transactions de la Box.
  List<Transaction> getAllTransactions() {
    return _transactionBox.values.toList();
  }

  /// Sauvegarde (ajoute ou met à jour) une transaction.
  Future<void> saveTransaction(Transaction transaction) async {
    await _transactionBox.put(transaction.id, transaction);
  }

  /// Supprime une transaction par son ID.
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionBox.delete(transactionId);
  }

  // --- FIN DES NOUVELLES MÉTHODES ---

  // --- MÉTHODES POUR LES MÉTADONNÉES D'ACTIFS ---

  /// Récupère les métadonnées d'un actif par son ticker.
  /// Retourne null si aucune métadonnée n'existe.
  AssetMetadata? getAssetMetadata(String ticker) {
    return _assetMetadataBox.get(ticker);
  }

  /// Récupère ou crée les métadonnées d'un actif.
  /// Si aucune métadonnée n'existe, crée une instance par défaut.
  AssetMetadata getOrCreateAssetMetadata(String ticker) {
    final existing = _assetMetadataBox.get(ticker);
    if (existing != null) return existing;

    final newMetadata = AssetMetadata(ticker: ticker);
    saveAssetMetadata(newMetadata);
    return newMetadata;
  }

  /// Sauvegarde ou met à jour les métadonnées d'un actif.
  Future<void> saveAssetMetadata(AssetMetadata metadata) async {
    await _assetMetadataBox.put(metadata.ticker, metadata);
  }

  /// Récupère toutes les métadonnées d'actifs.
  Map<String, AssetMetadata> getAllAssetMetadata() {
    final metadata = Map.fromEntries(
      _assetMetadataBox.values.map((m) => MapEntry(m.ticker, m)),
    );
    return metadata;
  }

  // --- FIN MÉTHODES MÉTADONNÉES ---

  /// Crée un portefeuille de démonstration et le sauvegarde.
  /// MODIFIÉ : Crée et sauvegarde également les transactions de démo.
  Portfolio createDemoPortfolio() {
    // 1. Obtenir les données de démo
    final demoData = _getDemoData();
    final portfolio = demoData.portfolio;
    final transactions = demoData.transactions;

    // 2. Sauvegarder le portefeuille
    savePortfolio(portfolio);

    // 3. Sauvegarder les transactions
    for (final tx in transactions) {
      saveTransaction(tx);
    }

    // 4. Retourner le portefeuille (il sera hydraté au prochain chargement)
    return portfolio;
  }

  /// Logique de génération des données de démo, MISE À JOUR AVEC LES TRANSACTIONS.
  ({Portfolio portfolio, List<Transaction> transactions}) _getDemoData() {
    final demoPortfolioId = _uuid.v4();
    final ctoAccountId = _uuid.v4();
    final peaAccountId = _uuid.v4();

    // --- TRANSACTIONS DE DÉMO ---
    final List<Transaction> demoTransactions = [
      // 1. Dépôt initial sur le CTO
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2024, 1, 15),
        amount: 5000.0, // +5000€
      ),
      // 2. Achat de "CW8" (ETF Amundi) sur le CTO
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Buy,
        date: DateTime(2024, 1, 20),
        assetTicker: 'CW8',
        assetName: 'AMUNDI MSCI WORLD UCITS ETF ACC',
        quantity: 5,
        price: 450.0, // 5 * 450 = 2250€
        fees: 9.90,
        amount: -2250.0, // Sortie d'argent
      ),
      // 3. Dépôt initial sur le PEA
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2024, 2, 1),
        amount: 10000.0, // +10000€
      ),
      // 4. Achat de "LVMH" sur le PEA
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Buy,
        date: DateTime(2024, 2, 5),
        assetTicker: 'MC.PA',
        assetName: 'LVMH Moët Hennessy Louis Vuitton SE',
        quantity: 10,
        price: 800.0, // 10 * 800 = 8000€
        fees: 15.0,
        amount: -8000.0,
      ),
      // 5. Dividende reçu sur le PEA (LVMH)
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Dividend,
        date: DateTime(2024, 5, 10),
        assetTicker: 'MC.PA',
        assetName: 'Dividende LVMH',
        amount: 70.0, // +70€
        fees: 0.0,
      ),
    ];

    // --- PORTEFEUILLE DE DÉMO ---
    final demoPortfolio = Portfolio(
      id: demoPortfolioId,
      name: "Portefeuille de Démo",
      institutions: [
        Institution(
          id: _uuid.v4(),
          name: 'Boursorama Banque',
          accounts: [
            Account(
              id: ctoAccountId, // ID défini ci-dessus
              name: 'Compte-Titres Ordinaire',
              type: AccountType.cto,
              // transactions: [], // Sera injecté au chargement
            ),
            Account(
              id: peaAccountId, // ID défini ci-dessus
              name: "Plan d'Épargne en Actions",
              type: AccountType.pea,
            ),
            Account(
              id: _uuid.v4(),
              name: 'Assurance Vie',
              type: AccountType.assuranceVie,
            ),
          ],
        ),
        Institution(
          id: _uuid.v4(),
          name: 'Coinbase',
          accounts: [
            Account(
              id: _uuid.v4(),
              name: 'Portefeuille Crypto',
              type: AccountType.crypto,
            ),
          ],
        ),
      ],
      savingsPlans: [
        SavingsPlan(
          id: _uuid.v4(),
          name: 'Achat mensuel d\'ETF World',
          monthlyAmount: 150.0,
          targetTicker: 'CW8', // Fait référence à l'actif du CTO
          isActive: true,
        ),
      ],
    );

    return (portfolio: demoPortfolio, transactions: demoTransactions);
  }
}