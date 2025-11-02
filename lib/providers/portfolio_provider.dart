import 'package:flutter/material.dart';
import '../models/portfolio.dart';
import '../models/institution.dart';
import '../models/account.dart';
import '../models/asset.dart';
import '../models/account_type.dart';

class PortfolioProvider extends ChangeNotifier {
  Portfolio? _portfolio;

  Portfolio? get portfolio => _portfolio;

  // TODO: Charger le portefeuille depuis Hive au démarrage

  void loadDemoPortfolio() {
    _portfolio = Portfolio(
      institutions: [
        Institution(
          name: 'Boursorama',
          accounts: [
            Account(
              name: 'CTO',
              type: AccountType.CTO,
              cashBalance: 150.75,
              assets: [
                Asset(name: 'Apple Inc.', ticker: 'AAPL', quantity: 10, averagePrice: 150.0, currentPrice: 175.2),
                Asset(name: 'Microsoft Corp.', ticker: 'MSFT', quantity: 15, averagePrice: 280.5, currentPrice: 310.8),
              ],
            ),
            Account(
              name: 'PEA',
              type: AccountType.PEA,
              cashBalance: 50.25,
              assets: [
                Asset(name: 'LVMH', ticker: 'MC', quantity: 5, averagePrice: 700.0, currentPrice: 850.5),
              ],
            ),
          ],
        ),
        Institution(
          name: 'Coinbase',
          accounts: [
            Account(
              name: 'Portefeuille Crypto',
              type: AccountType.Crypto,
              cashBalance: 200.0,
              assets: [
                Asset(name: 'Bitcoin', ticker: 'BTC', quantity: 0.05, averagePrice: 35000.0, currentPrice: 42000.0),
                Asset(name: 'Ethereum', ticker: 'ETH', quantity: 0.5, averagePrice: 2000.0, currentPrice: 2500.0),
              ],
            ),
          ],
        ),
      ],
    );
    notifyListeners();
  }

  void updatePortfolio(Portfolio portfolio) {
    _portfolio = portfolio;
    // TODO: Sauvegarder le portefeuille dans Hive
    notifyListeners();
  }

  void clearPortfolio() {
    _portfolio = null;
    // TODO: Supprimer le portefeuille de Hive
    notifyListeners();
  }
}
