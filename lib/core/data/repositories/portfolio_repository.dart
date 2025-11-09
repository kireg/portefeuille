import 'package:hive/hive.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/utils/constants.dart';
import 'package:uuid/uuid.dart'; // NOUVEL IMPORT

/// Classe responsable de la gestion des données du portefeuille.
/// Elle abstrait la source de données (Hive) du reste de l'application.
class PortfolioRepository {
  late final Box<Portfolio> _portfolioBox =
  Hive.box(AppConstants.kPortfolioBoxName);
  final _uuid = const Uuid(); // NOUVEAU : Générateur d'ID

  /// Charge TOUS les portefeuilles depuis la source de données.
  List<Portfolio> getAllPortfolios() {
    // MODIFIÉ : On charge toutes les valeurs, et non plus getAt(0)
    return _portfolioBox.values.toList();
  }

  /// Sauvegarde un portefeuille dans la source de données en utilisant son ID.
  Future<void> savePortfolio(Portfolio portfolio) async {
    // MODIFIÉ : On utilise l'ID comme clé
    await _portfolioBox.put(portfolio.id, portfolio);
  }

  /// Supprime un portefeuille spécifique.
  Future<void> deletePortfolio(String portfolioId) async {
    await _portfolioBox.delete(portfolioId);
  }

  /// Efface TOUTES les données (tous les portefeuilles).
  Future<void> deleteAllData() async {
    await _portfolioBox.clear();
  }

  /// Crée un nouveau portefeuille vide et le sauvegarde.
  Portfolio createEmptyPortfolio(String name) {
    // MODIFIÉ : Ajout de l'ID et du nom
    final portfolio = Portfolio(
      id: _uuid.v4(),
      name: name,
      institutions: [],
    );
    savePortfolio(portfolio);
    return portfolio;
  }

  /// Crée un portefeuille de démonstration et le sauvegarde.
  Portfolio createDemoPortfolio() {
    // MODIFIÉ : Appelle _getDemoData et sauvegarde
    final portfolio = _getDemoData();
    savePortfolio(portfolio);
    return portfolio;
  }

  // Logique de génération des données de démo, MISE À JOUR AVEC LES IDs.
  Portfolio _getDemoData() {
    final demoPortfolioId = _uuid.v4();
    return Portfolio(
      id: demoPortfolioId,
      name: "Portefeuille de Démo",
      institutions: [
        Institution(
          id: _uuid.v4(), // NOUVEAU
          name: 'Boursorama Banque',
          accounts: [
            Account(
              id: _uuid.v4(), // NOUVEAU
              name: 'Compte-Titres Ordinaire',
              type: AccountType.cto,
              cashBalance: 150.75,
              assets: [
                Asset(
                    id: _uuid.v4(), // NOUVEAU
                    name: 'Apple Inc.',
                    ticker: 'AAPL',
                    quantity: 10,
                    averagePrice: 150.0,
                    currentPrice: 175.2,
                    estimatedAnnualYield: 0.008),
                Asset(
                    id: _uuid.v4(), // NOUVEAU
                    name: 'Microsoft Corp.',
                    ticker: 'MSFT',
                    quantity: 15,
                    averagePrice: 280.5,
                    currentPrice: 310.8,
                    estimatedAnnualYield: 0.0095),
                Asset(
                    id: _uuid.v4(), // NOUVEAU
                    name: 'ETF S&P 500 UCITS',
                    ticker: 'CW8',
                    quantity: 25,
                    averagePrice: 80.0,
                    currentPrice: 95.0,
                    estimatedAnnualYield: 0.12),
              ],
            ),
            Account(
              id: _uuid.v4(), // NOUVEAU
              name: "Plan d'Épargne en Actions",
              type: AccountType.pea,
              cashBalance: 50.25,
              assets: [
                Asset(
                    id: _uuid.v4(), // NOUVEAU
                    name: 'LVMH Moët Hennessy',
                    ticker: 'MC',
                    quantity: 5,
                    averagePrice: 700.0,
                    currentPrice: 850.5,
                    estimatedAnnualYield: 0.016),
                Asset(
                    id: _uuid.v4(), // NOUVEAU
                    name: 'Airbus SE',
                    ticker: 'AIR',
                    quantity: 10,
                    averagePrice: 120.0,
                    currentPrice: 135.0,
                    estimatedAnnualYield: 0.012),
              ],
            ),
            Account(
              id: _uuid.v4(), // NOUVEAU
              name: 'Assurance Vie',
              type: AccountType.assuranceVie,
              cashBalance: 1000.0, // Fonds Euro
              assets: [],
            ),
          ],
        ),
        Institution(
          id: _uuid.v4(), // NOUVEAU
          name: 'Coinbase',
          accounts: [
            Account(
              id: _uuid.v4(), // NOUVEAU
              name: 'Portefeuille Crypto',
              type: AccountType.crypto,
              cashBalance: 200.0,
              assets: [
                Asset(
                    id: _uuid.v4(), // NOUVEAU
                    name: 'Bitcoin',
                    ticker: 'BTC',
                    quantity: 0.05,
                    averagePrice: 35000.0,
                    currentPrice: 42000.0,
                    estimatedAnnualYield: 0.45),
                Asset(
                    id: _uuid.v4(), // NOUVEAU
                    name: 'Ethereum',
                    ticker: 'ETH',
                    quantity: 0.5,
                    averagePrice: 2000.0,
                    currentPrice: 2500.0,
                    estimatedAnnualYield: 0.35),
              ],
            ),
          ],
        ),
      ],
      savingsPlans: [
        // Plan d'épargne mensuel de démonstration
        SavingsPlan(
          id: _uuid.v4(),
          name: 'Achat mensuel d\'ETF World',
          monthlyAmount: 150.0,
          targetTicker: 'CW8',
          targetAssetName: 'Amundi MSCI World',
          estimatedAnnualReturn: 0.07, // 7% de rendement annuel estimé
          isActive: true,
        ),
      ],
    );
  }
}