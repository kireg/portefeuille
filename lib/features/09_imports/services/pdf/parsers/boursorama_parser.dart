import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

class BoursoramaParser implements StatementParser {
  @override
  String get bankName => "Boursorama Banque";

  @override
  bool canParse(String rawText) {
    return rawText.contains("Boursorama") && rawText.contains("Avis d'opéré");
  }

  @override
  String? get warningMessage => null;

  AssetType _inferAssetType(String name) {
    final upper = name.toUpperCase();
    if (upper.contains('ETF') || upper.contains('MSCI') || upper.contains('S&P') || upper.contains('VANGUARD') || upper.contains('ISHARES') || upper.contains('AMUNDI')) {
      return AssetType.ETF;
    }
    if (upper.contains('COIN') || upper.contains('BITCOIN') || upper.contains('ETHEREUM') || upper.contains('BTC') || upper.contains('ETH') || upper.contains('SOLANA')) {
      return AssetType.Crypto;
    }
    return AssetType.Stock;
  }

  @override
  Future<List<ParsedTransaction>> parse(String rawText, {void Function(double)? onProgress}) async {
    final List<ParsedTransaction> transactions = [];
    
    // Regex pour Boursorama (Avis d'opéré classique)
    // "Achat au comptant de 10 LVMH à 850,00 EUR"
    // "Vente au comptant de 5 TOTALENERGIES à 55,00 EUR"
    
    final regexOrder = RegExp(
      r'(Achat|Vente)\s+au\s+comptant\s+de\s+(\d+)\s+(.*?)\s+à\s+([\d,]+)\s+(EUR)',
      caseSensitive: false,
    );

    // Extraction de la date d'exécution
    // "Date d'exécution : 12/05/2023"
    final regexDate = RegExp(r"Date d'exécution\s*:\s*(\d{2})/(\d{2})/(\d{4})");
    DateTime? docDate;
    final dateMatch = regexDate.firstMatch(rawText);
    if (dateMatch != null) {
      docDate = DateTime(
        int.parse(dateMatch.group(3)!),
        int.parse(dateMatch.group(2)!),
        int.parse(dateMatch.group(1)!),
      );
    }

    for (final match in regexOrder.allMatches(rawText)) {
      final typeStr = match.group(1)!.toLowerCase();
      final qtyStr = match.group(2)!;
      final assetName = match.group(3)!.trim();
      final priceStr = match.group(4)!.replaceAll(',', '.');
      final currency = match.group(5)!;

      final quantity = double.tryParse(qtyStr) ?? 0.0;
      final price = double.tryParse(priceStr) ?? 0.0;
      final amount = quantity * price;

      transactions.add(ParsedTransaction(
        date: docDate ?? DateTime.now(),
        type: typeStr == 'achat' ? TransactionType.Buy : TransactionType.Sell,
        assetName: assetName,
        quantity: quantity,
        price: price,
        amount: amount,
        fees: 0.0, // Frais souvent indiqués plus bas dans le tableau, difficile à choper avec une regex simple
        currency: currency,
        assetType: _inferAssetType(assetName),
      ));
    }

    return transactions;
  }
}
