// lib/features/00_app/services/demo_data_service.dart

import 'dart:math'; // Pour Random
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/portfolio_value_history_point.dart'; // Import nécessaire
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:uuid/uuid.dart';

class DemoDataService {
  final PortfolioRepository _repository;
  final Uuid _uuid;

  DemoDataService({
    required PortfolioRepository repository,
    Uuid? uuid,
  })  : _repository = repository,
        _uuid = uuid ?? const Uuid();

  /// Crée et sauvegarde un portefeuille de démo.
  /// Retourne le portfolio créé.
  Future<Portfolio> createDemoPortfolio() async {
    final data = _generateDemoData();

    await _repository.savePortfolio(data.portfolio);

    await Future.wait([
      ...data.transactions.map(_repository.saveTransaction),
      ...data.metadata.map(_repository.saveAssetMetadata),
    ]);

    return data.portfolio;
  }

  _DemoData _generateDemoData() {
    final demoPortfolioId = _uuid.v4();
    final ctoAccountId = _uuid.v4();
    final peaAccountId = _uuid.v4();
    final assuranceVieAccountId = _uuid.v4();
    final cryptoAccountId = _uuid.v4();

    // --- TRANSACTIONS DE DÉMO (2020-2025) ---
    final List<Transaction> demoTransactions = [
      // ===== 2020 : OUVERTURE DES COMPTES =====
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2020, 1, 15),
        amount: 5000.0,
      ),
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
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2020, 3, 1),
        amount: 3000.0,
      ),
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
      Transaction(
        id: _uuid.v4(),
        accountId: peaAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2021, 1, 5),
        amount: 500.0,
      ),
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
      Transaction(
        id: _uuid.v4(),
        accountId: ctoAccountId,
        type: TransactionType.Deposit,
        date: DateTime(2021, 6, 15),
        amount: 2000.0,
      ),
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
      // ▼▼▼ AJOUT : Génération d'un historique fictif ▼▼▼
      valueHistory: _generateFakeHistory(),
      // ▲▲▲ FIN AJOUT ▲▲▲
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

    // --- MÉTADONNÉES DES ACTIFS (Prix et Rendements) ---
    final List<AssetMetadata> demoMetadata = [
      AssetMetadata(
        ticker: 'CW8.PA',
        currentPrice: 500.0,
        estimatedAnnualYield: 0.085, // 8.5% annuel
        lastUpdated: DateTime(2025, 11, 12),
        isManualYield: false,
      ),
      AssetMetadata(
        ticker: 'MC.PA',
        currentPrice: 750.0,
        estimatedAnnualYield: 0.020, // Dividende ~2%
        lastUpdated: DateTime(2025, 11, 12),
        isManualYield: false,
      ),
      AssetMetadata(
        ticker: 'TTE.PA',
        currentPrice: 65.0,
        estimatedAnnualYield: 0.055, // Dividende élevé ~5.5%
        lastUpdated: DateTime(2025, 11, 12),
        isManualYield: false,
      ),
      AssetMetadata(
        ticker: 'AAPL',
        currentPrice: 220.0,
        estimatedAnnualYield: 0.005, // Dividende faible ~0.5%
        lastUpdated: DateTime(2025, 11, 12),
        isManualYield: false,
      ),
      AssetMetadata(
        ticker: 'MSFT',
        currentPrice: 430.0,
        estimatedAnnualYield: 0.008, // Dividende faible ~0.8%
        lastUpdated: DateTime(2025, 11, 12),
        isManualYield: false,
      ),
      AssetMetadata(
        ticker: 'BTC-EUR',
        currentPrice: 75000.0,
        estimatedAnnualYield: 0.0, // Pas de rendement
        lastUpdated: DateTime(2025, 11, 12),
        isManualYield: false,
      ),
      AssetMetadata(
        ticker: 'ETH-EUR',
        currentPrice: 3000.0,
        estimatedAnnualYield: 0.0, // Pas de rendement
        lastUpdated: DateTime(2025, 11, 12),
        isManualYield: false,
      ),
      AssetMetadata(
        ticker: 'FONDS-EUROS',
        currentPrice: 1.025,
        estimatedAnnualYield: 0.025, // 2.5% garanti
        lastUpdated: DateTime(2025, 11, 12),
        isManualYield: true, // Saisi manuellement
      ),
    ];

    return _DemoData(
      portfolio: demoPortfolio,
      transactions: demoTransactions,
      metadata: demoMetadata,
    );
  }

  /// Génère une courbe aléatoire "crédible" sur les 90 derniers jours
  List<PortfolioValueHistoryPoint> _generateFakeHistory() {
    final history = <PortfolioValueHistoryPoint>[];
    final random = Random();
    final now = DateTime.now();

    // Valeur cible approximative (basée sur le portefeuille de démo)
    double currentValue = 42000.0;

    // On remonte le temps jour par jour
    for (int i = 90; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));

      // On ajoute un bruit aléatoire pour simuler la volatilité du marché
      // Variation entre -1.5% et +1.6% par jour (légère tendance haussière globale)

      history.add(PortfolioValueHistoryPoint(
        date: date,
        value: currentValue,
      ));

      // Pour la prochaine itération (qui est en fait la veille dans cette boucle inversée si on construisait à l'envers,
      // mais ici on construit une liste triée chronologiquement à la fin, donc je dois faire évoluer la valeur "vers le passé" ou "vers le futur")

      // Mieux : Construisons la liste de J-90 à J-0.
      // J-90 valeur de départ : environ 38 000
      // On avance jour par jour.
    }

    // Correction : Approche itérative propre
    history.clear();
    double value = 38000.0; // Valeur de départ arbitraire il y a 90 jours

    for (int i = 90; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));

      // Ajout du point
      history.add(PortfolioValueHistoryPoint(
        date: date,
        value: value,
      ));

      // Calcul de la valeur du lendemain
      // Volatilité
      double change = (random.nextDouble() * 0.04) - 0.018; // -1.8% à +2.2%
      value = value * (1 + change);
    }

    return history;
  }
}

class _DemoData {
  final Portfolio portfolio;
  final List<Transaction> transactions;
  final List<AssetMetadata> metadata;

  const _DemoData({
    required this.portfolio,
    required this.transactions,
    required this.metadata,
  });
}