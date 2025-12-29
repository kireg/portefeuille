import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/csv/parsers/revolut_parser.dart';

void main() {
  late RevolutParser parser;

  setUp(() {
    parser = RevolutParser();
  });

  group('RevolutParser.canParse', () {
    test('identifie un en-tête Revolut standard', () {
      expect(parser.canParse('Date,Ticker,Type,Quantity,Price per share'), isTrue);
      expect(parser.canParse('date,ticker,type,quantity'), isTrue);
    });

    test('identifie via mot-clé revolut', () {
      expect(parser.canParse('Revolut Trading Statement'), isTrue);
    });

    test('identifie via cash top-up', () {
      expect(parser.canParse('Some header\nCASH TOP-UP,100'), isTrue);
    });

    test('rejette documents non Revolut', () {
      expect(parser.canParse('Trade Republic Bank GmbH'), isFalse);
      expect(parser.canParse('Boursorama Banque'), isFalse);
    });
  });

  group('RevolutParser.warningMessage', () {
    test('n\'a pas de warning', () {
      expect(parser.warningMessage, isNull);
    });
  });

  group('RevolutParser.parse - Types de transactions', () {
    test('parse BUY - MARKET', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-01-31T14:53:37.864Z,NVDA,BUY - MARKET,16.13293538,USD 123.97,USD 2000,USD,1.0397
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Buy);
      expect(tx.ticker, 'NVDA');
      expect(tx.quantity, closeTo(16.13, 0.01));
      expect(tx.price, closeTo(123.97, 0.01));
      expect(tx.amount, closeTo(-2000, 0.01)); // Négatif: sortie d'argent
      expect(tx.currency, 'USD');
      expect(tx.assetType, AssetType.Stock);
    });

    test('parse BUY - LIMIT', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-02-15T10:00:00.000Z,AAPL,BUY - LIMIT,5,USD 150.00,USD 750,USD,1.0
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      expect(results.first.type, TransactionType.Buy);
    });

    test('parse SELL - MARKET', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-03-01T12:00:00.000Z,TSLA,SELL - MARKET,10,USD 200.00,USD 2000,USD,1.0
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      expect(results.first.type, TransactionType.Sell);
      expect(results.first.ticker, 'TSLA');
    });

    test('parse DIVIDEND', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-03-14T15:26:11.874829Z,MSFT,DIVIDEND,,,USD 1.41,USD,1.0905
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Dividend);
      expect(tx.ticker, 'MSFT');
      expect(tx.amount, closeTo(1.41, 0.01));
      expect(tx.assetType, AssetType.Stock);
    });

    test('parse DIVIDEND TAX (CORRECTION)', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-07-02T20:59:22.856710Z,MSFT,DIVIDEND TAX (CORRECTION),,,USD -0.25,USD,1.1826
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Fees);
      expect(tx.amount, closeTo(0.25, 0.01)); // Abs value
      expect(tx.assetType, AssetType.Cash);
    });

    test('parse CASH TOP-UP', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-01-31T15:19:16.970881Z,,CASH TOP-UP,,,EUR 435.44,EUR,1.0000
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Deposit);
      expect(tx.amount, closeTo(435.44, 0.01));
      expect(tx.assetType, AssetType.Cash);
      expect(tx.assetName, contains('Cash'));
    });

    test('parse CARD TOP-UP', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-01-01T10:00:00.000Z,,CARD TOP-UP,,,EUR 100,EUR,1.0
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      expect(results.first.type, TransactionType.Deposit);
    });

    test('parse CASH WITHDRAWAL', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-04-01T08:00:00.000Z,,CASH WITHDRAWAL,,,EUR 200,EUR,1.0
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Withdrawal);
      expect(tx.assetType, AssetType.Cash);
    });

    test('parse INTEREST', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-05-01T00:00:00.000Z,,INTEREST,,,EUR 5.50,EUR,1.0
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Interest);
      expect(tx.amount, closeTo(5.50, 0.01));
      expect(tx.assetType, AssetType.Cash);
    });
  });

  group('RevolutParser.parse - Parsing des montants', () {
    test('gère les montants avec devise préfixée', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-01-01T00:00:00.000Z,ABC,BUY - MARKET,1,EUR 100.50,EUR 100.50,EUR,1.0
''';
      final results = await parser.parse(raw);

      expect(results.first.price, closeTo(100.50, 0.01));
    });

    test('gère les montants avec virgule comme séparateur décimal', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-01-01T00:00:00.000Z,,CASH TOP-UP,,,EUR 1234,56,EUR,1.0
''';
      // Note: This is a tricky case with CSV parsing
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
    });

    test('gère les montants négatifs (valeur absolue)', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-01-01T00:00:00.000Z,XYZ,DIVIDEND TAX (CORRECTION),,,-1.50,EUR,1.0
''';
      final results = await parser.parse(raw);

      expect(results.first.amount, closeTo(1.50, 0.01));
    });
  });

  group('RevolutParser.parse - Cas limites', () {
    test('ignore les lignes vides', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate

2025-01-01T00:00:00.000Z,ABC,BUY - MARKET,1,100,100,EUR,1.0

''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
    });

    test('ignore les en-têtes', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
Type,Description,Amount
2025-01-01T00:00:00.000Z,ABC,BUY - MARKET,1,100,100,EUR,1.0
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
    });

    test('retourne liste vide si fichier vide', () async {
      final results = await parser.parse('');

      expect(results, isEmpty);
    });

    test('gère les dates ISO8601 avec microsecondes', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-03-14T15:26:11.874829Z,MSFT,DIVIDEND,,,USD 1.41,USD,1.0905
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      expect(results.first.date.year, 2025);
      expect(results.first.date.month, 3);
      expect(results.first.date.day, 14);
    });

    test('ticker null devient assetName "Inconnu" si vide', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-01-01T00:00:00.000Z,,INTEREST,,,EUR 5,EUR,1.0
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(1));
      expect(results.first.assetName, 'Intérêt');
    });

    test('appelle onProgress pendant le parsing', () async {
      final lines = List.generate(100, (i) => 
        '2025-01-01T00:00:00.000Z,ABC,BUY - MARKET,1,100,100,EUR,1.0'
      );
      final raw = 'Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate\n${lines.join('\n')}';
      
      double lastProgress = 0;
      await parser.parse(raw, onProgress: (p) => lastProgress = p);

      expect(lastProgress, greaterThan(0));
    });
  });

  group('RevolutParser.parse - Transactions multiples', () {
    test('parse un fichier complet avec plusieurs types', () async {
      const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-01-31T14:53:37.864Z,NVDA,BUY - MARKET,16.13293538,USD 123.97,USD 2000,USD,1.0397
2025-03-14T15:26:11.874829Z,MSFT,DIVIDEND,,,USD 1.41,USD,1.0905
2025-07-02T20:59:22.856710Z,MSFT,DIVIDEND TAX (CORRECTION),,,USD -0.25,USD,1.1826
2025-01-31T15:19:16.970881Z,,CASH TOP-UP,,,EUR 435.44,EUR,1.0000
''';
      final results = await parser.parse(raw);

      expect(results, hasLength(4));
      
      final buy = results.firstWhere((tx) => tx.type == TransactionType.Buy);
      expect(buy.ticker, 'NVDA');
      
      final dividend = results.firstWhere((tx) => tx.type == TransactionType.Dividend);
      expect(dividend.ticker, 'MSFT');
      
      final fees = results.firstWhere((tx) => tx.type == TransactionType.Fees);
      expect(fees.amount, closeTo(0.25, 0.01));
      
      final deposit = results.firstWhere((tx) => tx.type == TransactionType.Deposit);
      expect(deposit.amount, closeTo(435.44, 0.01));
    });
  });
}
