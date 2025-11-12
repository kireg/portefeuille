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
import 'package:portefeuille/core/data/models/asset_type.dart';
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
    final assuranceVieAccountId = _uuid.v4();
    final cryptoAccountId = _uuid.v4();

    // --- TRANSACTIONS DE DÉMO (2020-2025) ---
    final List<Transaction> demoTransactions = [
      // ===== 2020 : OUVERTURE DES COMPTES =====
      
      // PEA - Dépôt initial
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2020, 1, 15),
        amount: 5000.0,
      ),
      // PEA - Premier achat ETF World (CW8)
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Buy,
        date: DateTime(2020, 1, 20),
        assetTicker: 'CW8.PA',
        assetName: 'Amundi MSCI World UCITS ETF',
        assetType: AssetType.ETF,
        quantity: 15,
        price: 300.0,
        fees: 7.50,
        amount: -4500.0,
      ),
      
      // CTO - Dépôt initial
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2020, 3, 1),
        amount: 3000.0,
      ),
      // CTO - Achat AAPL
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Buy,
        date: DateTime(2020, 3, 10),
        assetTicker: 'AAPL',
        assetName: 'Apple Inc.',
        assetType: AssetType.Stock,
        quantity: 20,
        price: 120.0,
        fees: 9.90,
        amount: -2400.0,
      ),

      // ===== 2021 : RENFORCEMENT RÉGULIER =====
      
      // PEA - Dépôt mensuel
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2021, 1, 5),
        amount: 500.0,
      ),
      // PEA - Achat LVMH
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Buy,
        date: DateTime(2021, 1, 10),
        assetTicker: 'MC.PA',
        assetName: 'LVMH Moët Hennessy Louis Vuitton',
        assetType: AssetType.Stock,
        quantity: 1,
        price: 480.0,
        fees: 5.0,
        amount: -480.0,
      ),
      
      // CTO - Dépôt
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2021, 6, 15),
        amount: 2000.0,
      ),
      // CTO - Achat MSFT
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Buy,
        date: DateTime(2021, 6, 20),
        assetTicker: 'MSFT',
        assetName: 'Microsoft Corporation',
        assetType: AssetType.Stock,
        quantity: 5,
        price: 280.0,
        fees: 9.90,
        amount: -1400.0,
      ),
      
      // Crypto - Premier investissement
      Transaction(
        id: _uuid.v4(),
        accountId: cryptoAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2021, 11, 1),
        amount: 1500.0,
      ),
      Transaction(
        id: _uuid.v4(),
        accountId: cryptoAccountId,
        type: TransactionType.Buy,
        date: DateTime(2021, 11, 5),
        assetTicker: 'BTC-EUR',
        assetName: 'Bitcoin',
        assetType: AssetType.Crypto,
        quantity: 0.03,
        price: 50000.0,
        fees: 7.50,
        amount: -1500.0,
      ),

      // ===== 2022 : DIVERSIFICATION =====
      
      // PEA - Renforcement CW8 (PRU)
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2022, 3, 1),
        amount: 2000.0,
      ),
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Buy,
        date: DateTime(2022, 3, 5),
        assetTicker: 'CW8.PA',
        assetName: 'Amundi MSCI World UCITS ETF',
        assetType: AssetType.ETF,
        quantity: 5,
        price: 380.0,
        fees: 5.0,
        amount: -1900.0,
      ),
      
      // PEA - Achat TotalEnergies
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Buy,
        date: DateTime(2022, 5, 10),
        assetTicker: 'TTE.PA',
        assetName: 'TotalEnergies SE',
        assetType: AssetType.Stock,
        quantity: 15,
        price: 48.0,
        fees: 5.0,
        amount: -720.0,
      ),
      
      // Assurance Vie - Ouverture
      Transaction(
        id: _uuid.v4(),
        accountId: assuranceVieAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2022, 9, 1),
        amount: 10000.0,
      ),
      Transaction(
        id: _uuid.v4(),
        accountId: assuranceVieAccountId,
        type: TransactionType.Buy,
        date: DateTime(2022, 9, 5),
        assetTicker: 'FONDS-EUROS',
        assetName: 'Fonds en Euros Suravenir',
        assetType: AssetType.Other,
        quantity: 10000,
        price: 1.0,
        fees: 0.0,
        amount: -10000.0,
      ),

      // ===== 2023 : PREMIERS DIVIDENDES =====
      
      // Dividende LVMH
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Dividend,
        date: DateTime(2023, 4, 15),
        assetTicker: 'MC.PA',
        assetName: 'Dividende LVMH',
        amount: 12.0,
        fees: 0.0,
      ),
      
      // Dividende TotalEnergies
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Dividend,
        date: DateTime(2023, 6, 20),
        assetTicker: 'TTE.PA',
        assetName: 'Dividende TotalEnergies',
        amount: 9.75,
        fees: 0.0,
      ),
      
      // Intérêts Fonds Euros
      Transaction(
        id: _uuid.v4(),
        accountId: assuranceVieAccountId,
        type: TransactionType.Interest,
        date: DateTime(2023, 12, 31),
        assetTicker: 'FONDS-EUROS',
        assetName: 'Intérêts Fonds Euros 2023',
        amount: 250.0,
        fees: 0.0,
      ),

      // ===== 2024 : PRISE DE PROFIT =====
      
      // CTO - Vente partielle AAPL (plus-value)
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Sell,
        date: DateTime(2024, 2, 10),
        assetTicker: 'AAPL',
        assetName: 'Apple Inc.',
        assetType: AssetType.Stock,
        quantity: 10,
        price: 185.0,
        fees: 9.90,
        amount: 1850.0,
      ),
      
      // Crypto - Achat ETH
      Transaction(
        id: _uuid.v4(),
        accountId: cryptoAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2024, 5, 1),
        amount: 1000.0,
      ),
      Transaction(
        id: _uuid.v4(),
        accountId: cryptoAccountId,
        type: TransactionType.Buy,
        date: DateTime(2024, 5, 5),
        assetTicker: 'ETH-EUR',
        assetName: 'Ethereum',
        assetType: AssetType.Crypto,
        quantity: 0.5,
        price: 2000.0,
        fees: 5.0,
        amount: -1000.0,
      ),
      
      // PEA - Dividendes 2024
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Dividend,
        date: DateTime(2024, 4, 15),
        assetTicker: 'MC.PA',
        assetName: 'Dividende LVMH',
        amount: 13.0,
        fees: 0.0,
      ),
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Dividend,
        date: DateTime(2024, 6, 20),
        assetTicker: 'TTE.PA',
        assetName: 'Dividende TotalEnergies',
        amount: 10.50,
        fees: 0.0,
      ),

      // ===== 2025 : RENFORCEMENT RÉCENT =====
      
      // PEA - Dernier renforcement CW8
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2025, 1, 10),
        amount: 3000.0,
      ),
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Buy,
        date: DateTime(2025, 1, 15),
        assetTicker: 'CW8.PA',
        assetName: 'Amundi MSCI World UCITS ETF',
        assetType: AssetType.ETF,
        quantity: 6,
        price: 480.0,
        fees: 5.0,
        amount: -2880.0,
      ),
      
      // CTO - Renforcement MSFT
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2025, 3, 1),
        amount: 1500.0,
      ),
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Buy,
        date: DateTime(2025, 3, 5),
        assetTicker: 'MSFT',
        assetName: 'Microsoft Corporation',
        assetType: AssetType.Stock,
        quantity: 3,
        price: 420.0,
        fees: 9.90,
        amount: -1260.0,
      ),
      
      // Frais de gestion annuels
      Transaction(
        id: _uuid.v4(),
        accountId: assuranceVieAccountId,
        type: TransactionType.Fees,
        date: DateTime(2025, 1, 1),
        amount: -50.0,
        notes: 'Frais de gestion annuels Assurance Vie',
      ),
    ];

    // --- PORTEFEUILLE DE DÉMO ---
    final demoPortfolio = Portfolio(
      id: demoPortfolioId,
      name: "Portefeuille de Démo (2020-2025)",
      institutions: [
        Institution(
          id: _uuid.v4(),
          name: 'Boursorama Banque',
          accounts: [
            Account(
              id: peaAccountId,
              name: "Plan d'Épargne en Actions",
              type: AccountType.pea,
            ),
            Account(
              id: ctoAccountId,
              name: 'Compte-Titres Ordinaire',
              type: AccountType.cto,
            ),
          ],
        ),
        Institution(
          id: _uuid.v4(),
          name: 'Linxea Avenir',
          accounts: [
            Account(
              id: assuranceVieAccountId,
              name: 'Assurance Vie',
              type: AccountType.assuranceVie,
            ),
          ],
        ),
        Institution(
          id: _uuid.v4(),
          name: 'Kraken',
          accounts: [
            Account(
              id: cryptoAccountId,
              name: 'Portefeuille Crypto',
              type: AccountType.crypto,
            ),
          ],
        ),
      ],
      savingsPlans: [
        SavingsPlan(
          id: _uuid.v4(),
          name: 'DCA ETF World (PEA)',
          monthlyAmount: 300.0,
          targetTicker: 'CW8.PA',
          isActive: true,
        ),
        SavingsPlan(
          id: _uuid.v4(),
          name: 'DCA Bitcoin',
          monthlyAmount: 100.0,
          targetTicker: 'BTC-EUR',
          isActive: true,
        ),
      ],
    );

    return (portfolio: demoPortfolio, transactions: demoTransactions);
  }
}
