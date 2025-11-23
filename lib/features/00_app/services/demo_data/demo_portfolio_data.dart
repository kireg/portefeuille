import 'dart:math';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/portfolio_value_history_point.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:uuid/uuid.dart';

Portfolio getDemoPortfolio(
  Uuid uuid,
  String portfolioId,
  String peaAccountId,
  String ctoAccountId,
  String assuranceVieAccountId,
  String cryptoAccountId,
) {
  return Portfolio(
    id: portfolioId,
    name: "Portefeuille de Démo (2020-2025)",
    valueHistory: _generateFakeHistory(),
    institutions: [
      Institution(
        id: uuid.v4(),
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
        id: uuid.v4(),
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
        id: uuid.v4(),
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
        id: uuid.v4(),
        name: 'DCA ETF World (PEA)',
        monthlyAmount: 300.0,
        targetTicker: 'CW8.PA',
        isActive: true,
      ),
      SavingsPlan(
        id: uuid.v4(),
        name: 'DCA Bitcoin',
        monthlyAmount: 100.0,
        targetTicker: 'BTC-EUR',
        isActive: true,
      ),
    ],
  );
}

List<PortfolioValueHistoryPoint> _generateFakeHistory() {
  final history = <PortfolioValueHistoryPoint>[];
  final random = Random();
  final now = DateTime.now();

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
    final double change = (random.nextDouble() * 0.04) - 0.018; // -1.8% à +2.2%
    value = value * (1 + change);
  }

  return history;
}
