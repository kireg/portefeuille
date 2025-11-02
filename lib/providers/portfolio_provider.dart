import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/portfolio.dart';
import '../models/institution.dart';
import '../models/account.dart';
import '../models/asset.dart';
import '../models/account_type.dart';

class PortfolioProvider extends ChangeNotifier {
  Portfolio? _portfolio;
  final Box<Portfolio> _portfolioBox = Hive.box('portfolio_box');

  Portfolio? get portfolio => _portfolio;

  PortfolioProvider() {
    _loadPortfolio();
  }

  void _loadPortfolio() {
    // On essaie de charger le premier (et seul) portefeuille de la boîte.
    if (_portfolioBox.isNotEmpty) {
      _portfolio = _portfolioBox.getAt(0);
      notifyListeners();
    }
  }

  void loadDemoPortfolio() {
    _portfolio = _createDemoPortfolio();
    _savePortfolio();
    notifyListeners();
  }

  void updatePortfolio(Portfolio portfolio) {
    _portfolio = portfolio;
    _savePortfolio();
    notifyListeners();
  }

  void clearPortfolio() {
    _portfolio = null;
    _portfolioBox.clear(); // Vide toute la boîte
    notifyListeners();
  }

  void _savePortfolio() {
    if (_portfolio != null) {
      _portfolioBox.put(0, _portfolio!); // Sauvegarde le portefeuille à l'index 0
    }
  }

  Portfolio _createDemoPortfolio() {
     return Portfolio(
      institutions: [
        Institution(
          name: 'Boursorama',
          accounts: [
            Account(
              name: 'CTO',
              type: AccountType.cto,
              cashBalance: 150.75,
              assets: [
                Asset(name: 'Apple Inc.', ticker: 'AAPL', quantity: 10, averagePrice: 150.0, currentPrice: 175.2),
                Asset(name: 'Microsoft Corp.', ticker: 'MSFT', quantity: 15, averagePrice: 280.5, currentPrice: 310.8),
              ],
            ),
            Account(
              name: 'PEA',
              type: AccountType.pea,
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
              type: AccountType.crypto,
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
  }
}
