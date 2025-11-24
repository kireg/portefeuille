import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_parser.dart';

void main() {
  group('TradeRepublicParser', () {
    final parser = TradeRepublicParser();

    test('canParse returns true for Trade Republic documents', () {
      expect(parser.canParse("Trade Republic Bank GmbH"), isTrue);
      expect(parser.canParse("TRADE REPUBLIC"), isTrue);
      expect(parser.canParse("Boursorama"), isFalse);
    });

    test('parse extracts buy order correctly', () {
      const rawText = """
      TRADE REPUBLIC
      Date : 12.05.2023
      
      Achat de 10 titres Apple Inc. au cours de 150,00 EUR
      Montant total : 1500,00 EUR
      """;

      final transactions = parser.parse(rawText);

      expect(transactions.length, 1);
      final tx = transactions.first;
      expect(tx.type, TransactionType.Buy);
      expect(tx.assetName, "Apple Inc.");
      expect(tx.quantity, 10.0);
      expect(tx.price, 150.0);
      expect(tx.currency, "EUR");
      expect(tx.date, DateTime(2023, 5, 12));
    });

    test('parse extracts sell order correctly', () {
      const rawText = """
      TRADE REPUBLIC
      Date : 15.06.2023
      
      Vente de 5,5 titres Tesla Inc. au cours de 200,50 USD
      """;

      final transactions = parser.parse(rawText);

      expect(transactions.length, 1);
      final tx = transactions.first;
      expect(tx.type, TransactionType.Sell);
      expect(tx.assetName, "Tesla Inc.");
      expect(tx.quantity, 5.5);
      expect(tx.price, 200.5);
      expect(tx.currency, "USD");
      expect(tx.date, DateTime(2023, 6, 15));
    });
  });
}
