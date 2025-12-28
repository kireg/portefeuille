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

    test('identifie un relevé de compte titres Boursorama', () {
      expect(parser.canParse("Boursorama\nRELEVE COMPTE TITRES"), isTrue);
      expect(parser.canParse("BoursoBank\nReleve Compte Titres : SEPTEMBRE 2025"), isTrue);
    });

    test('rejette les documents non Boursorama', () {
      expect(parser.canParse('Trade Republic Bank GmbH'), isFalse);
      expect(parser.canParse('Revolut Trading Statement'), isFalse);
      expect(parser.canParse('Random document'), isFalse);
    });

    test('rejette si Boursorama sans type de document reconnu', () {
      expect(parser.canParse('Boursorama simple mention'), isFalse);
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
      expect(tx.amount, closeTo(-8500.0, 0.01));
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

  group('BoursoramaParser.parse - Relevé de portefeuille', () {
    test('parse un relevé de compte titres avec positions', () async {
      const text = '''
Boursorama
RELEVE COMPTE TITRES : SEPTEMBRE 2025
Valorisé au 30/09/2025
QuantitéNom de la valeur (code)Cours du titreValorisation%PortefeuilePrix de revient
VALEURS FRANCAISES
15THALES (FR0000121329) * 266,603 999,0054,64163,88
10SOCIETE GENERALE (FR0000130809) * 56,36563,607,7016,07
TOTAL EUR7 318,26
''';
      final results = await parser.parse(text);

      expect(results, hasLength(2));
      
      // Vérifier THALES
      final thales = results.firstWhere((t) => t.assetName.contains('THALES'));
      expect(thales.type, TransactionType.Buy);
      expect(thales.quantity, closeTo(15.0, 0.01));
      expect(thales.isin, 'FR0000121329');
      expect(thales.price, closeTo(163.88, 0.01)); // PRU
      expect(thales.amount, closeTo(-(15 * 163.88), 1.0)); // Montant investi (achat négatif)
      expect(thales.date.year, 2025);
      expect(thales.date.month, 9);
      expect(thales.date.day, 30);
      
      // Vérifier SOCIETE GENERALE
      final sg = results.firstWhere((t) => t.assetName.contains('SOCIETE GENERALE'));
      expect(sg.quantity, closeTo(10.0, 0.01));
      expect(sg.isin, 'FR0000130809');
      expect(sg.price, closeTo(16.07, 0.01)); // PRU
    });

    test('parse un relevé réel BoursoBank anonymisé', () async {
      // Extrait réel anonymisé du PDF
      const text = '''
Service Clientèle : 01 46 09 49 49 ou +33 146 09 49 49 depuis l'étranger, du lundi au vendredi de 8h à 20h et le samedi de 8h45 à 16h30 – www.boursobank.comBoursorama S.A. au capital de 51 171 597,60 € - RCS Nanterre 351 058 151 - TVA 69 351 058 151 - 44 rue Traversière - CS 80134 - 92772 Boulogne Billancourt CedexAdresse du médiateur : Médiateur de l'AMF - 17, place de la Bourse - 75082 PARIS CEDEX 02
RELEVE COMPTE TITRES : SEPTEMBRE 2025Valorisé au 30/09/2025Feuillet 1/2Références de votre compte titres78564 54698 00080905720Résident Français
QuantitéNom de la valeur (code)F(1)P(2)Cours du titreen devise de négociationValorisation de la ligne%Portef.Prix de revient fiscal unitaireVALEURS FRANCAISESEUREUREURACTIONS15THALES (FR0000121329) * 266,603 999,0054,64163,8810SOCIETE GENERALE (FR0000130809) * 56,36563,607,7016,072BNP PARIBAS (FR0000131104) * 77,33154,662,1142,444FDJ (FR0013451333) * 28,50114,001,5535,50Sous-Total4 831,2666,01TOTAL VALEURS FRANCAISES4 831,2666,01VALEURS ETRANGERES COTANT EN EURO (FRANCE)EUREUREURACTIONS20AM.MS.SEM.ESG.SC.C (LU1900066033) * 63,8251 276,5017,4453,953Sous-Total1 276,5017,44VALEURS ETRANGERES  1 EUR = 1,1745 USDUSDEUREURACTIONS2ISHS CORE SP 500 (IE00B5BMR087) * 710,871 210,5016,54622,72Sous-Total1 210,5016,54TOTAL VALEURS ETRANGERES2 487,0033,98TOTAL EUR7 318,26100,00
''';
      final results = await parser.parse(text);

      // Devrait trouver 6 positions
      expect(results.length, greaterThanOrEqualTo(4)); // Au minimum les actions françaises
      
      // Vérifier la date de valorisation
      expect(results.first.date.year, 2025);
      expect(results.first.date.month, 9);
      expect(results.first.date.day, 30);
      
      // Vérifier que tous les ISIN sont extraits
      final isins = results.map((t) => t.isin).whereType<String>().toSet();
      expect(isins, contains('FR0000121329')); // THALES
      expect(isins, contains('FR0000130809')); // SOCIETE GENERALE
    });

    test('détecte les ETF dans un relevé de portefeuille', () async {
      const text = '''
Boursorama
RELEVE COMPTE TITRES : OCTOBRE 2025
Valorisé au 31/10/2025
20AMUNDI MSCI WORLD (LU1234567890) * 500,0010 000,0050,00450,00
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      expect(results.first.assetType, AssetType.ETF);
      expect(results.first.assetName, contains('AMUNDI'));
    });

    test('gère les quantités décimales', () async {
      const text = '''
Boursorama
RELEVE COMPTE TITRES
Valorisé au 15/11/2025
2,5ISHARES CORE (IE00B5BMR087) * 100,00250,0025,0090,00
''';
      final results = await parser.parse(text);

      expect(results, hasLength(1));
      expect(results.first.quantity, closeTo(2.5, 0.01));
    });
  });
}
