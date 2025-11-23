import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/aggregated_portfolio_data.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_calculation_provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/services/calculation_service.dart';

import 'package:portefeuille/core/data/abstractions/i_settings.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/services/api_service.dart';

// Mocks
class MockSettings implements ISettings {
  @override
  String get baseCurrency => 'EUR';
  @override
  String? get fmpApiKey => null;
  @override
  bool get hasFmpApiKey => false;
  @override
  int get appColorValue => 0xFF0000FF;
}

class MockApiService extends ApiService {
  MockApiService() : super(settings: MockSettings());
}

class MockPortfolioProvider extends ChangeNotifier implements PortfolioProvider {
  @override
  Portfolio? activePortfolio;
  
  @override
  Map<String, AssetMetadata> allMetadata = {};

  @override
  bool isLoading = false;

  @override
  bool isProcessingInBackground = false;

  @override
  Future<void> updateHistory(double totalValue) async {}
  
  // Implement other members as needed (dummy)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  String baseCurrency = 'EUR';
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCalculationService extends CalculationService {
  MockCalculationService() : super(apiService: MockApiService());

  @override
  Future<AggregatedPortfolioData> calculate({
    required Portfolio? portfolio,
    required String targetCurrency,
    required Map<String, AssetMetadata> allMetadata,
  }) async {
    if (portfolio == null) return AggregatedPortfolioData.empty;
    
    return AggregatedPortfolioData(
      baseCurrency: targetCurrency,
      totalValue: 1000.0,
      totalPL: 100.0,
      totalInvested: 900.0,
      accountValues: {},
      accountPLs: {},
      accountInvested: {},
      assetTotalValues: {},
      assetPLs: {},
      aggregatedAssets: [],
      valueByAssetType: {},
      estimatedAnnualYield: 0.05,
      failedConversions: ['FAIL'],
    );
  }
}

void main() {
  late PortfolioCalculationProvider provider;
  late MockPortfolioProvider mockPortfolioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockCalculationService mockCalculationService;

  setUp(() {
    mockPortfolioProvider = MockPortfolioProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockCalculationService = MockCalculationService();

    provider = PortfolioCalculationProvider(
      calculationService: mockCalculationService,
      portfolioProvider: mockPortfolioProvider,
      settingsProvider: mockSettingsProvider,
    );
  });

  test('calculate should update aggregatedData and expose values', () async {
    // Arrange
    mockPortfolioProvider.activePortfolio = Portfolio(
      id: 'p1',
      name: 'Test',
      institutions: [],
      savingsPlans: [],
    );

    // Act
    await provider.calculate();

    // Assert
    expect(provider.activePortfolioTotalValue, 1000.0);
    expect(provider.activePortfolioTotalPL, 100.0);
    expect(provider.hasConversionError, true);
    expect(provider.failedConversions, contains('FAIL'));
  });

  test('calculate should handle null portfolio', () async {
    // Arrange
    mockPortfolioProvider.activePortfolio = null;

    // Act
    await provider.calculate();

    // Assert
    expect(provider.activePortfolioTotalValue, 0.0);
  });
}
