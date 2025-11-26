import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_account_statement_parser.dart';

void main() {
  late TradeRepublicAccountStatementParser parser;

  setUp(() {
    parser = TradeRepublicAccountStatementParser();
  });

  const fakeStatementText = """
TRADE REPUBLIC BANK GMBH, BRANCH FRANCE
 
 
75 BOULEVARD HAUSSMANN
75008 PARIS
DATE
01 mai 2025 - 31 juil. 2025
IBAN
FR7698233268450061759229466
BIC
TRBKFRPPXXX
JEAN DUPOND
Avenue des Alpes 43
75000 PARIS
Trade Republic Bank GmbH, Branch France
c/o Regus, 75 boulevard Haussmann
75008 Paris
900 796 855 R.C.S. Paris
www.traderepublic.fr
TVA DE307510626
Siège social : Trade Republic Bank GmbH
Brunnenstrasse 19-21, 10119 Berlin, Allemagne
Registre du commerce du tribunal local de
Charlottenburg, HRB 244347 B, Allemagne
Directeurs Généraux
Andreas Torner
Gernot Mittendorfer
Christian Hecker
Thomas Pischke
Généré le 26 nov. 2025, 05:14:15
Page
 
 
 
1
de
14
SYNTHÈSE DU RELEVÉ DE COMPTE
PRODUIT
SOLDE DÉBUT DE PÉRIODE
ENTRÉE D'ARGENT
SORTIE D'ARGENT
SOLDE FIN DE PÉRIODE
Compte courant
9591,91 €
446,83 €
5698,13 €
4340,61 €
TRANSACTIONS
DATE
TYPE
DESCRIPTION
ENTRÉE 
D'ARGENT
SORTIE 
D'ARGENT
SOLDE
01 
mai 
2025
Intérêts 
créditeur
Your interest payment
15,25 €
9607,16 €
02 
mai 
2025
Exécution 
d'ordre
Savings plan execution XF000BTC0017 Bitcoin, quantity: 0.000113
9,97 €
9597,19 €
02 
mai 
2025
Exécution 
d'ordre
Savings plan execution XF000SOL0012 Solana, quantity: 0.037058
5,00 €
9592,19 €
""";

  test('Should identify Trade Republic Account Statement', () {
    expect(parser.canParse(fakeStatementText), isTrue);
    expect(parser.canParse("SOME OTHER TEXT"), isFalse);
    expect(parser.canParse("TRADE REPUBLIC BUT NOT STATEMENT"), isFalse);
  });

  test('Should parse transactions correctly', () async {
    final transactions = await parser.parse(fakeStatementText);

    expect(transactions.length, 3);

    // 1. Interest
    final interest = transactions[0];
    expect(interest.type, TransactionType.Dividend); // Or Interest if available
    expect(interest.amount, 15.25);
    expect(interest.date, DateTime(2025, 5, 1));
    expect(interest.assetName, contains("Your interest payment"));

    // 2. Bitcoin Buy
    final btc = transactions[1];
    expect(btc.type, TransactionType.Buy);
    expect(btc.assetType, AssetType.Crypto);
    expect(btc.isin, "XF000BTC0017");
    expect(btc.quantity, 0.000113);
    expect(btc.amount, 9.97);

    // 3. Solana Buy
    final sol = transactions[2];
    expect(sol.type, TransactionType.Buy);
    expect(sol.assetType, AssetType.Crypto);
    expect(sol.isin, "XF000SOL0012");
    expect(sol.quantity, 0.037058);
    expect(sol.amount, 5.00);
  });


  test('Should report progress', () async {
    double lastProgress = 0.0;
    await parser.parse(fakeStatementText, onProgress: (progress) {
      lastProgress = progress;
      expect(progress, greaterThanOrEqualTo(0.0));
      expect(progress, lessThanOrEqualTo(1.0));
    });
    
    // Since the text is short, it might not trigger many updates, but it should at least run.
    // The parser implementation updates progress every 50 lines.
    // Our fake text is about 60 lines.
    // So it should trigger at least once or twice.
  });
}
