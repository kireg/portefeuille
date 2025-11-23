import 'package:flutter/foundation.dart';
import 'package:portefeuille/core/data/models/aggregated_asset.dart';
import 'package:portefeuille/core/data/models/aggregated_portfolio_data.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/projection_data.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/services/calculation_service.dart';

class PortfolioCalculationProvider extends ChangeNotifier {
  final CalculationService _calculationService;
  final PortfolioProvider _portfolioProvider;
  final SettingsProvider _settingsProvider;

  AggregatedPortfolioData _aggregatedData = AggregatedPortfolioData.empty;
  bool _isCalculating = false;

  AggregatedPortfolioData get aggregatedData => _aggregatedData;
  bool get isCalculating => _isCalculating;

  // Getters - Données calculées
  String get currentBaseCurrency => _aggregatedData.baseCurrency;
  double get activePortfolioTotalValue => _aggregatedData.totalValue;
  double get activePortfolioTotalInvested => _aggregatedData.totalInvested;
  double get activePortfolioCashValue => _aggregatedData.valueByAssetType[AssetType.Cash] ?? 0.0;
  double get activePortfolioTotalPL => _aggregatedData.totalPL;
  double get activePortfolioTotalPLPercentage {
    if (_aggregatedData.totalInvested == 0.0) return 0.0;
    return _aggregatedData.totalPL / _aggregatedData.totalInvested;
  }

  double get activePortfolioEstimatedAnnualYield =>
      _aggregatedData.estimatedAnnualYield;

  double getConvertedAccountValue(String accountId) =>
      _aggregatedData.accountValues[accountId] ?? 0.0;
  double getConvertedAccountPL(String accountId) =>
      _aggregatedData.accountPLs[accountId] ?? 0.0;
  double getConvertedAccountInvested(String accountId) =>
      _aggregatedData.accountInvested[accountId] ?? 0.0;

  double getConvertedAssetTotalValue(String assetId) =>
      _aggregatedData.assetTotalValues[assetId] ?? 0.0;
  double getConvertedAssetPL(String assetId) =>
      _aggregatedData.assetPLs[assetId] ?? 0.0;

  List<AggregatedAsset> get aggregatedAssets =>
      _aggregatedData.aggregatedAssets;
  Map<AssetType, double> get aggregatedValueByAssetType =>
      _aggregatedData.valueByAssetType;

  bool get hasCrowdfunding =>
      (_aggregatedData.valueByAssetType[AssetType.RealEstateCrowdfunding] ?? 0.0) > 0;

  PortfolioCalculationProvider({
    required CalculationService calculationService,
    required PortfolioProvider portfolioProvider,
    required SettingsProvider settingsProvider,
  })  : _calculationService = calculationService,
        _portfolioProvider = portfolioProvider,
        _settingsProvider = settingsProvider;

  Future<void> calculate() async {
    if (_portfolioProvider.activePortfolio == null) {
      _aggregatedData = AggregatedPortfolioData.empty;
      notifyListeners();
      return;
    }

    _isCalculating = true;
    notifyListeners();

    final targetCurrency = _settingsProvider.baseCurrency;
    
    try {
      debugPrint("🔄 [CalculationProvider] Calcul en cours pour ${_portfolioProvider.activePortfolio!.name} en $targetCurrency");
      _aggregatedData = await _calculationService.calculate(
        portfolio: _portfolioProvider.activePortfolio,
        targetCurrency: targetCurrency,
        allMetadata: _portfolioProvider.allMetadata,
      );
      debugPrint("  -> ✅ Calcul OK. Valeur totale: ${_aggregatedData.totalValue} $targetCurrency");
      
      // Mise à jour de l'historique dans le PortfolioProvider
      if (_portfolioProvider.activePortfolio != null && !_portfolioProvider.isLoading) {
        await _portfolioProvider.updateHistory(_aggregatedData.totalValue);
      }

    } catch (e) {
      debugPrint("  -> ❌ ERREUR CALCUL: $e");
      debugPrint("  -> StackTrace: ${StackTrace.current}");
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  List<ProjectionData> getProjectionData(int duration) {
    if (_portfolioProvider.activePortfolio == null) return [];

    final totalValue = _aggregatedData.totalValue;
    final totalInvested = _aggregatedData.totalInvested;
    final portfolioAnnualYield = activePortfolioEstimatedAnnualYield;

    double totalMonthlyInvestment = 0;
    double weightedPlansYield = 0;

    for (var plan in _portfolioProvider.activePortfolio!.savingsPlans.where((p) => p.isActive)) {
      final targetAsset = _portfolioProvider.findAssetByTicker(plan.targetTicker);
      final assetYield = (targetAsset?.estimatedAnnualYield ?? 0.0);
      totalMonthlyInvestment += plan.monthlyAmount;
      weightedPlansYield += plan.monthlyAmount * assetYield;
    }

    final double averagePlansYield = (totalMonthlyInvestment > 0)
        ? weightedPlansYield / totalMonthlyInvestment
        : 0.0;

    return ProjectionCalculator.generateProjectionData(
      duration: duration,
      initialPortfolioValue: totalValue,
      initialInvestedCapital: totalInvested,
      portfolioAnnualYield: portfolioAnnualYield,
      totalMonthlyInvestment: totalMonthlyInvestment,
      averagePlansYield: averagePlansYield,
    );
  }
}
