import 'package:hive/hive.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/utils/constants.dart';

/// Classe responsable de la gestion des données du portefeuille.
/// Elle abstrait la source de données (Hive) du reste de l'application.
class PortfolioRepository {
  // Référence paresseuse à la boîte Hive
  late final Box<Portfolio> _portfolioBox = Hive.box(AppConstants.kPortfolioBoxName);

  /// Charge le portefeuille depuis la source de données.
  Portfolio? loadPortfolio() {
    if (_portfolioBox.isNotEmpty) {
      return _portfolioBox.getAt(0);
    }
    return null;
  }

  /// Sauvegarde le portefeuille dans la source de données.
  Future<void> savePortfolio(Portfolio portfolio) async {
    await _portfolioBox.put(0, portfolio);
  }

  /// Efface toutes les données du portefeuille.
  Future<void> clearPortfolio() async {
    await _portfolioBox.clear();
  }

  /// Crée un nouveau portefeuille vide et le sauvegarde.
  Portfolio createEmptyPortfolio() {
    final portfolio = Portfolio(institutions: []);
    savePortfolio(portfolio);
    return portfolio;
  }

  /// Crée un portefeuille de démonstration et le sauvegarde.
  Portfolio createDemoPortfolio() {
    final portfolio = _getDemoData();
    savePortfolio(portfolio);
    return portfolio;
  }

  // Logique de génération des données de démo, déplacée depuis le Provider.
  Portfolio _getDemoData() {
    return Portfolio(
      institutions: [
        Institution(
          name: 'Boursorama Banque',
          accounts: [
            Account(
              name: 'Compte-Titres Ordinaire',
              type: AccountType.cto,
              cashBalance: 150.75,
              assets: [
                Asset(name: 'Apple Inc.', ticker: 'AAPL', quantity: 10, averagePrice: 150.0, currentPrice: 175.2, estimatedAnnualYield: 0.008),
                Asset(name: 'Microsoft Corp.', ticker: 'MSFT', quantity: 15, averagePrice: 280.5, currentPrice: 310.8, estimatedAnnualYield: 0.0095),
                Asset(name: 'ETF S&P 500 UCITS', ticker: 'CW8', quantity: 25, averagePrice: 80.0, currentPrice: 95.0, estimatedAnnualYield: 0.12),
              ],
            ),
            Account(
              name: "Plan d'Épargne en Actions",
              type: AccountType.pea,
              cashBalance: 50.25,
              assets: [
                Asset(name: 'LVMH Moët Hennessy', ticker: 'MC', quantity: 5, averagePrice: 700.0, currentPrice: 850.5, estimatedAnnualYield: 0.016),
                Asset(name: 'Airbus SE', ticker: 'AIR', quantity: 10, averagePrice: 120.0, currentPrice: 135.0, estimatedAnnualYield: 0.012),
              ],
            ),
            Account(
              name: 'Assurance Vie',
              type: AccountType.assuranceVie,
              cashBalance: 1000.0, // Fonds Euro
              assets: [],
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
                Asset(name: 'Bitcoin', ticker: 'BTC', quantity: 0.05, averagePrice: 35000.0, currentPrice: 42000.0, estimatedAnnualYield: 0.45),
                Asset(name: 'Ethereum', ticker: 'ETH', quantity: 0.5, averagePrice: 2000.0, currentPrice: 2500.0, estimatedAnnualYield: 0.35),
              ],
            ),
          ],
        ),
      ],
    );
  }
}