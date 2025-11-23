import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/abstractions/i_settings.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/services/calculation_service.dart';

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

  @override
  List<String> get serviceOrder => ['FMP', 'Yahoo', 'Google'];
}

class MockApiService extends ApiService {
  MockApiService() : super(settings: MockSettings());

  @override
  Future<double> getExchangeRate(String from, String to) async {
    if (from == 'USD' && to == 'EUR') return 0.85;
    if (from == 'FAIL' && to == 'EUR') throw Exception('Network Error');
    return 1.0;
  }
}

void main() {
  late CalculationService service;
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
    service = CalculationService(apiService: mockApi);
  });

  test('calculate should aggregate values correctly with conversion', () async {
    // Arrange
    final txBuy = Transaction(
      id: 't1',
      accountId: 'acc1',
      type: TransactionType.Buy,
      date: DateTime.now(),
      assetTicker: 'AAPL',
      assetName: 'Apple',
      quantity: 10,
      price: 100, // 1000 USD
      amount: -1000, // Negative for Buy
      fees: 0,
      assetType: AssetType.Stock,
      priceCurrency: 'USD',
      exchangeRate: 1.0,
    );

    final assetUSD = Asset(
      id: '1',
      ticker: 'AAPL',
      name: 'Apple',
      type: AssetType.Stock,
      priceCurrency: 'USD',
      currentPrice: 150, // 1500 USD value
      transactions: [txBuy],
    );

    // Cash Balance logic: We need a deposit to have cash?
    // Or we can just mock cashBalance if Account allows it?
    // Account calculates cashBalance from transactions.
    // Deposit 1100. Buy 1000. Cash = 100.
    final txDeposit = Transaction(
      id: 't0',
      accountId: 'acc1',
      type: TransactionType.Deposit,
      date: DateTime.now(),
      amount: 1100,
      assetTicker: '',
      assetName: '',
      quantity: 0,
      price: 0,
      fees: 0,
      assetType: AssetType.Cash,
      priceCurrency: 'USD',
    );

    final accountUSD = Account(
      id: 'acc1',
      name: 'US Account',
      type: AccountType.cto,
      currency: 'USD',
      transactions: [txDeposit, txBuy],
    )..assets = [assetUSD];

    final institution = Institution(
      id: 'inst1',
      name: 'Broker',
      accounts: [accountUSD],
    );

    final portfolio = Portfolio(
      id: 'p1',
      name: 'Test Portfolio',
      institutions: [institution],
      savingsPlans: [],
    );

    // Act
    final result = await service.calculate(
      portfolio: portfolio,
      targetCurrency: 'EUR',
      allMetadata: {},
    );

    // Assert
    // Rate USD -> EUR = 0.85
    // Asset Value USD = 10 * 150 = 1500 USD
    // Cash Value USD = 1100 - 1000 = 100 USD
    // Total Value USD = 1600 USD
    // Total Value EUR = 1600 * 0.85 = 1360 EUR
    expect(result.totalValue, closeTo(1360.0, 0.01));
    
    // Invested USD = 1000 USD (Cost basis of asset)
    // Invested EUR = 1000 * 0.85 = 850 EUR
    // Note: Cash is not "Invested" usually, or is it?
    // Account.totalInvestedCapital sums assets.totalInvestedCapital.
    // Asset invested = 1000.
    expect(result.totalInvested, closeTo(850.0, 0.01));

    // PL USD = 1500 - 1000 = 500 USD
    // PL EUR = 500 * 0.85 = 425 EUR
    expect(result.totalPL, closeTo(425.0, 0.01));
  });

  test('calculate should handle conversion errors by using fallback 1.0 and reporting error', () async {
    // Arrange
    final txDeposit = Transaction(
      id: 't2',
      accountId: 'acc2',
      type: TransactionType.Deposit,
      date: DateTime.now(),
      amount: 100,
      assetTicker: '',
      assetName: '',
      quantity: 0,
      price: 0,
      fees: 0,
      assetType: AssetType.Cash,
      priceCurrency: 'FAIL',
    );

    final accountFail = Account(
      id: 'acc2',
      name: 'Fail Account',
      type: AccountType.cto,
      currency: 'FAIL',
      transactions: [txDeposit],
    );

    final institution = Institution(
      id: 'inst1',
      name: 'Bank',
      accounts: [accountFail],
    );

    final portfolio = Portfolio(
      id: 'p1',
      name: 'Test Portfolio',
      institutions: [institution],
      savingsPlans: [],
    );

    // Act
    final result = await service.calculate(
      portfolio: portfolio,
      targetCurrency: 'EUR',
      allMetadata: {},
    );

    // Assert
    // Rate FAIL -> EUR fails, fallback 1.0
    // Value = 100 * 1.0 = 100
    expect(result.totalValue, 100.0);
    
    // Check error reporting
    expect(result.failedConversions, contains('FAIL'));
  });

  test('calculate should reflect negative cash balance when Buy transactions have negative amount', () async {
    // Arrange
    // 10 Buys of 1000 USD each. Amount should be -1000.
    final transactions = List.generate(10, (index) {
      return Transaction(
        id: 't_buy_$index',
        accountId: 'acc_mass',
        type: TransactionType.Buy,
        date: DateTime.now(),
        amount: -1000, // Correct negative amount
        assetTicker: 'AAPL',
        assetName: 'Apple',
        quantity: 10, // 10 * 100 = 1000
        price: 100,
        fees: 0,
        assetType: AssetType.Stock,
        priceCurrency: 'USD',
        exchangeRate: 1.0,
      );
    });

    final assetAAPL = Asset(
      id: 'asset_aapl',
      ticker: 'AAPL',
      name: 'Apple',
      type: AssetType.Stock,
      priceCurrency: 'USD',
      currentPrice: 100,
      transactions: transactions,
    );

    final account = Account(
      id: 'acc_mass',
      name: 'Mass Account',
      type: AccountType.cto,
      currency: 'USD',
      transactions: transactions,
    )..assets = [assetAAPL];

    final portfolio = Portfolio(
      id: 'p_mass',
      name: 'Mass Portfolio',
      institutions: [Institution(id: 'i1', name: 'Inst', accounts: [account])],
      savingsPlans: [],
    );

    // Act
    final result = await service.calculate(
      portfolio: portfolio,
      targetCurrency: 'USD', // Keep simple
      allMetadata: {},
    );

    // Assert
    // Assets Value = 10 * (10 * 100) = 10,000 USD
    // Cash Balance = 10 * (-1000) = -10,000 USD
    // Total Value = 0 USD
    expect(result.valueByAssetType[AssetType.Stock], 10000.0);
    expect(result.valueByAssetType[AssetType.Cash], -10000.0);
    expect(result.totalValue, 0.0);
  });

  test('calculate should IGNORE cash impact if Buy transactions have ZERO amount (Bad Import)', () async {
    // Arrange
    // 10 Buys of 1000 USD each. Amount is 0 (Simulating bad import).
    final transactions = List.generate(10, (index) {
      return Transaction(
        id: 't_buy_bad_$index',
        accountId: 'acc_bad',
        type: TransactionType.Buy,
        date: DateTime.now(),
        amount: 0, // INCORRECT amount
        assetTicker: 'AAPL',
        assetName: 'Apple',
        quantity: 10,
        price: 100,
        fees: 0,
        assetType: AssetType.Stock,
        priceCurrency: 'USD',
        exchangeRate: 1.0,
      );
    });

    final assetAAPL = Asset(
      id: 'asset_aapl_bad',
      ticker: 'AAPL',
      name: 'Apple',
      type: AssetType.Stock,
      priceCurrency: 'USD',
      currentPrice: 100,
      transactions: transactions,
    );

    final account = Account(
      id: 'acc_bad',
      name: 'Bad Account',
      type: AccountType.cto,
      currency: 'USD',
      transactions: transactions,
    )..assets = [assetAAPL];

    final portfolio = Portfolio(
      id: 'p_bad',
      name: 'Bad Portfolio',
      institutions: [Institution(id: 'i1', name: 'Inst', accounts: [account])],
      savingsPlans: [],
    );

    // Act
    final result = await service.calculate(
      portfolio: portfolio,
      targetCurrency: 'USD',
      allMetadata: {},
    );

    // Assert
    // Assets Value = 10,000 USD
    // Cash Balance = 0 USD (Because amount was 0)
    // Total Value = 10,000 USD
    expect(result.valueByAssetType[AssetType.Stock], 10000.0);
    expect(result.valueByAssetType[AssetType.Cash] ?? 0.0, 0.0);
    expect(result.totalValue, 10000.0);
  });
}
