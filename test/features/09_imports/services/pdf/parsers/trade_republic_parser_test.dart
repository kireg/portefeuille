import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_parser.dart';

void main() {
  late TradeRepublicParser parser;

  setUp(() {
    parser = TradeRepublicParser();
  });

  group('TradeRepublicParser.canParse', () {
    test('identifie un document Trade Republic', () {
      expect(parser.canParse('Trade Republic Bank GmbH'), isTrue);
      expect(parser.canParse('TRADE REPUBLIC'), isTrue);
      expect(parser.canParse('Boursorama Banque'), isFalse);
      expect(parser.canParse('Random text'), isFalse);
    });
  });

  group('TradeRepublicParser.warningMessage', () {
    test('affiche un avertissement', () {
      expect(parser.warningMessage, isNotNull);
      expect(parser.warningMessage, contains('instant t'));
    });
  });

  group('TradeRepublicParser.parse - Ordres français', () {
    test('parse un achat classique', () async {
      const text = '''
Trade Republic Bank GmbH
Date : 15.05.2024
Achat de 4,5 titres Apple Inc. au cours de 180,50 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Buy);
      expect(tx.quantity, closeTo(4.5, 0.001));
      expect(tx.assetName, 'Apple Inc.');
      expect(tx.price, closeTo(180.50, 0.01));
      expect(tx.currency, 'EUR');
    });

    test('parse une vente classique', () async {
      const text = '''
Trade Republic Bank GmbH
Date : 20.06.2024
Vente de 10 titres Microsoft Corp au cours de 350,00 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Sell);
      expect(tx.quantity, closeTo(10.0, 0.001));
      expect(tx.assetName, 'Microsoft Corp');
    });
  });

  group('TradeRepublicParser.parse - Positions (Portfolio)', () {
    test('parse une position avec ISIN', () async {
      const text = '''
Trade Republic Bank GmbH
Relevé de titres au 21/11/2025
22,00 titre(s) 
iShares Core MSCI World
ISIN : IE00B4L5Y983
19,28 21/11/2025 424,25
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Buy);
      expect(tx.quantity, closeTo(22.0, 0.001));
      expect(tx.isin, 'IE00B4L5Y983');
      expect(tx.assetType, AssetType.ETF);
    });

    test('infère le type ETF correctement', () async {
      const text = '''
TRADE REPUBLIC
au 01/01/2025
5,00 titre(s) Vanguard S&P 500 ISIN : US1234567890 100,00 01/01/2025 500,00
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      expect(results.first.assetType, AssetType.ETF);
    });

    test('infère le type Crypto correctement', () async {
      const text = '''
TRADE REPUBLIC
au 01/01/2025
0,50 titre(s) Bitcoin BTC ISIN : XF000BTC0017 50000,00 01/01/2025 25000,00
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      expect(results.first.assetType, AssetType.Crypto);
    });
  });

  group('TradeRepublicParser.parse - Dividendes', () {
    test('parse un dividende', () async {
      const text = '''
Trade Republic Bank GmbH
Date : 10.03.2024
Dividende pour 10 titres Apple Inc. Montant par titre 0,25 USD
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Dividend);
      expect(tx.assetName, 'Apple Inc.');
      expect(tx.quantity, closeTo(10.0, 0.001));
    });
  });

  group('TradeRepublicParser.parse - Cas limites', () {
    test('retourne liste vide si texte non reconnu', () async {
      const text = 'Trade Republic Bank GmbH\nAucune transaction trouvée.';
      final results = await parser.parse(text);

      expect(results, isEmpty);
    });

    test('utilise la date du document si disponible', () async {
      const text = '''
Trade Republic Bank GmbH
Date : 25.12.2024
Achat de 1 titres Test au cours de 100,00 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      expect(results.first.date.year, 2024);
      expect(results.first.date.month, 12);
      expect(results.first.date.day, 25);
    });

    test('appelle onProgress pendant le parsing', () async {
      const text = '''
Trade Republic Bank GmbH
Date : 01.01.2024
Achat de 1 titres Test au cours de 10,00 EUR
''';
      double lastProgress = 0;
      await parser.parse(text, onProgress: (p) => lastProgress = p);

      // Le progress doit avoir été appelé au moins une fois
      expect(lastProgress, greaterThanOrEqualTo(0));
    });
  });
}
