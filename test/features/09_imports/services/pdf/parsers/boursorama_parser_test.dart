import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/boursorama_parser.dart';

void main() {
  late BoursoramaParser parser;

  setUp(() {
    parser = BoursoramaParser();
  });

  group('BoursoramaParser.canParse', () {
    test('identifie un avis d\'opéré Boursorama', () {
      expect(parser.canParse("Boursorama\nAvis d'opéré\nAchat"), isTrue);
      expect(parser.canParse("Boursorama Banque Avis d'opéré"), isTrue);
    });

    test('rejette les documents non Boursorama', () {
      expect(parser.canParse('Trade Republic Bank GmbH'), isFalse);
      expect(parser.canParse('Revolut Trading Statement'), isFalse);
      expect(parser.canParse('Random document'), isFalse);
    });

    test('rejette si Boursorama sans Avis d\'opéré', () {
      expect(parser.canParse('Boursorama relevé mensuel'), isFalse);
    });
  });

  group('BoursoramaParser.warningMessage', () {
    test('n\'a pas de warning', () {
      expect(parser.warningMessage, isNull);
    });
  });

  group('BoursoramaParser.parse - Achats/Ventes', () {
    test('parse un achat au comptant', () async {
      const text = '''
Boursorama Banque
Avis d'opéré
Date d'exécution : 15/05/2024
Achat au comptant de 10 LVMH à 850,00 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Buy);
      expect(tx.quantity, closeTo(10.0, 0.001));
      expect(tx.assetName, 'LVMH');
      expect(tx.price, closeTo(850.0, 0.01));
      expect(tx.amount, closeTo(8500.0, 0.01));
      expect(tx.currency, 'EUR');
    });

    test('parse une vente au comptant', () async {
      const text = '''
Boursorama Banque
Avis d'opéré
Date d'exécution : 20/06/2024
Vente au comptant de 5 TOTALENERGIES à 55,00 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      final tx = results.first;
      expect(tx.type, TransactionType.Sell);
      expect(tx.quantity, closeTo(5.0, 0.001));
      expect(tx.assetName, 'TOTALENERGIES');
      expect(tx.price, closeTo(55.0, 0.01));
    });

    test('parse plusieurs opérations dans un document', () async {
      const text = '''
Boursorama Banque
Avis d'opéré
Date d'exécution : 10/03/2024
Achat au comptant de 20 AIR LIQUIDE à 180,00 EUR
Vente au comptant de 15 SANOFI à 90,50 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(2));
      expect(results[0].type, TransactionType.Buy);
      expect(results[0].assetName, 'AIR LIQUIDE');
      expect(results[1].type, TransactionType.Sell);
      expect(results[1].assetName, 'SANOFI');
    });
  });

  group('BoursoramaParser.parse - Dates', () {
    test('extrait la date d\'exécution', () async {
      const text = '''
Boursorama
Avis d'opéré
Date d'exécution : 25/12/2024
Achat au comptant de 1 TEST à 100,00 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      expect(results.first.date.year, 2024);
      expect(results.first.date.month, 12);
      expect(results.first.date.day, 25);
    });

    test('utilise date actuelle si non trouvée', () async {
      const text = '''
Boursorama
Avis d'opéré
Achat au comptant de 1 TEST à 100,00 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      // La date sera DateTime.now(), on vérifie juste qu'elle existe
      expect(results.first.date, isNotNull);
    });
  });

  group('BoursoramaParser.parse - Inférence du type d\'actif', () {
    test('détecte un ETF via le nom', () async {
      const text = '''
Boursorama
Avis d'opéré
Date d'exécution : 01/01/2024
Achat au comptant de 5 AMUNDI MSCI WORLD à 500,00 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      expect(results.first.assetType, AssetType.ETF);
    });

    test('détecte une action par défaut', () async {
      const text = '''
Boursorama
Avis d'opéré
Date d'exécution : 01/01/2024
Achat au comptant de 10 ORANGE à 10,00 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      expect(results.first.assetType, AssetType.Stock);
    });
  });

  group('BoursoramaParser.parse - Cas limites', () {
    test('retourne liste vide si aucune opération trouvée', () async {
      const text = '''
Boursorama
Avis d'opéré
Aucune transaction ce mois-ci.
''';
      final results = await parser.parse(text);

      expect(results, isEmpty);
    });

    test('gère les prix avec virgule', () async {
      const text = '''
Boursorama
Avis d'opéré
Date d'exécution : 01/01/2024
Achat au comptant de 100 BNP PARIBAS à 65,75 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      expect(results.first.price, closeTo(65.75, 0.01));
    });

    test('les frais sont à 0 par défaut', () async {
      const text = '''
Boursorama
Avis d'opéré
Date d'exécution : 01/01/2024
Achat au comptant de 1 TEST à 100,00 EUR
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      expect(results.first.fees, 0.0);
    });
  });
}
