import 'package:flutter/foundation.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

class BoursoramaParser implements StatementParser {
  @override
  String get bankName => "Boursorama Banque";

  @override
  bool canParse(String rawText) {
    final lower = rawText.toLowerCase();
    // Supporte les avis d'opéré et les relevés de compte
    return lower.contains("boursorama") && 
           (lower.contains("avis d'opéré") || 
            lower.contains("relevé de compte") ||
            lower.contains("dividende") ||
            lower.contains("coupon"));
  }

  @override
  String? get warningMessage => null;

  AssetType _inferAssetType(String name) {
    final upper = name.toUpperCase();
    if (upper.contains('ETF') || upper.contains('MSCI') || upper.contains('S&P') || 
        upper.contains('VANGUARD') || upper.contains('ISHARES') || upper.contains('AMUNDI')) {
      return AssetType.ETF;
    }
    if (upper.contains('OBLIGATION') || upper.contains('BOND') || upper.contains('OAT')) {
      return AssetType.Bond;
    }
    if (upper.contains('COIN') || upper.contains('BITCOIN') || upper.contains('ETHEREUM') || 
        upper.contains('BTC') || upper.contains('ETH') || upper.contains('SOLANA')) {
      return AssetType.Crypto;
    }
    return AssetType.Stock;
  }

  @override
  Future<List<ParsedTransaction>> parse(String rawText, {void Function(double)? onProgress}) async {
    final List<ParsedTransaction> transactions = [];
    
    // Extraction de la date d'exécution (plusieurs formats possibles)
    DateTime? docDate = _extractDate(rawText);

    // --- 1. Achats/Ventes au comptant ---
    // "Achat au comptant de 10 LVMH à 850,00 EUR"
    // "Vente au comptant de 5 TOTALENERGIES à 55,00 EUR"
    final regexOrder = RegExp(
      r'(Achat|Vente)\s+au\s+comptant\s+de\s+([\d.,]+)\s+(.*?)\s+à\s+([\d\s,]+)\s*(EUR|€)',
      caseSensitive: false,
    );

    for (final match in regexOrder.allMatches(rawText)) {
      try {
        final typeStr = match.group(1)!.toLowerCase();
        final qtyStr = match.group(2)!.replaceAll(',', '.').replaceAll(' ', '');
        final assetName = match.group(3)!.trim();
        final priceStr = match.group(4)!.replaceAll(',', '.').replaceAll(' ', '');

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
          fees: 0.0,
          currency: 'EUR',
          assetType: _inferAssetType(assetName),
        ));
      } catch (e) {
        debugPrint('BoursoramaParser: Error parsing order: $e');
      }
    }

    // --- 2. Dividendes ---
    // "Dividende LVMH : 12,50 EUR" ou "DIVIDENDE 10 APPLE INC 5,00 USD"
    final regexDividend = RegExp(
      r'[Dd]ividende[s]?\s+(?:sur\s+)?(?:(\d+)\s+)?([A-Za-z][A-Za-z0-9\s\.&\-]+?)(?:\s*:\s*|\s+)([\d\s,]+)\s*(EUR|USD|€|\$)',
      caseSensitive: false,
    );

    for (final match in regexDividend.allMatches(rawText)) {
      try {
        final qtyStr = match.group(1);
        final assetName = match.group(2)!.trim();
        final amountStr = match.group(3)!.replaceAll(',', '.').replaceAll(' ', '');
        final currency = _normalizeCurrency(match.group(4)!);

        final quantity = qtyStr != null ? (double.tryParse(qtyStr) ?? 0.0) : 0.0;
        final amount = double.tryParse(amountStr) ?? 0.0;

        transactions.add(ParsedTransaction(
          date: docDate ?? DateTime.now(),
          type: TransactionType.Dividend,
          assetName: assetName,
          quantity: quantity,
          price: 0,
          amount: amount,
          fees: 0.0,
          currency: currency,
          assetType: _inferAssetType(assetName),
        ));
      } catch (e) {
        debugPrint('BoursoramaParser: Error parsing dividend: $e');
      }
    }

    // --- 3. Coupons (obligations) ---
    // "Coupon OAT 2.5% : 25,00 EUR"
    final regexCoupon = RegExp(
      r'[Cc]oupon\s+([A-Za-z][A-Za-z0-9\s\.%\-]+?)(?:\s*:\s*|\s+)([\d\s,]+)\s*(EUR|€)',
      caseSensitive: false,
    );

    for (final match in regexCoupon.allMatches(rawText)) {
      try {
        final assetName = match.group(1)!.trim();
        final amountStr = match.group(2)!.replaceAll(',', '.').replaceAll(' ', '');

        final amount = double.tryParse(amountStr) ?? 0.0;

        transactions.add(ParsedTransaction(
          date: docDate ?? DateTime.now(),
          type: TransactionType.Interest, // Coupon = intérêts d'obligation
          assetName: assetName,
          quantity: 0,
          price: 0,
          amount: amount,
          fees: 0.0,
          currency: 'EUR',
          assetType: AssetType.Bond,
        ));
      } catch (e) {
        debugPrint('BoursoramaParser: Error parsing coupon: $e');
      }
    }

    // --- 4. Frais de courtage (optionnel, extraction si visible) ---
    // "Frais de courtage : 4,90 EUR" ou "Commission : 1,99 EUR"
    final regexFees = RegExp(
      r'(?:[Ff]rais\s+(?:de\s+)?courtage|[Cc]ommission)\s*:\s*([\d\s,]+)\s*(EUR|€)',
      caseSensitive: false,
    );

    // On associe les frais à la dernière transaction si trouvée
    final feesMatch = regexFees.firstMatch(rawText);
    if (feesMatch != null && transactions.isNotEmpty) {
      final feesStr = feesMatch.group(1)!.replaceAll(',', '.').replaceAll(' ', '');
      final fees = double.tryParse(feesStr) ?? 0.0;
      
      // Appliquer les frais à la première transaction d'achat/vente
      final orderIdx = transactions.indexWhere(
        (t) => t.type == TransactionType.Buy || t.type == TransactionType.Sell
      );
      if (orderIdx >= 0) {
        final tx = transactions[orderIdx];
        transactions[orderIdx] = ParsedTransaction(
          date: tx.date,
          type: tx.type,
          assetName: tx.assetName,
          isin: tx.isin,
          ticker: tx.ticker,
          quantity: tx.quantity,
          price: tx.price,
          amount: tx.amount,
          fees: fees,
          currency: tx.currency,
          assetType: tx.assetType,
        );
      }
    }

    return transactions;
  }

  DateTime? _extractDate(String rawText) {
    // Format 1: "Date d'exécution : 12/05/2023"
    final regexDate1 = RegExp(r"[Dd]ate\s+d'exécution\s*:\s*(\d{2})/(\d{2})/(\d{4})");
    final match1 = regexDate1.firstMatch(rawText);
    if (match1 != null) {
      return DateTime(
        int.parse(match1.group(3)!),
        int.parse(match1.group(2)!),
        int.parse(match1.group(1)!),
      );
    }

    // Format 2: "12/05/2023" seul en début de ligne
    final regexDate2 = RegExp(r'(\d{2})/(\d{2})/(\d{4})');
    final match2 = regexDate2.firstMatch(rawText);
    if (match2 != null) {
      return DateTime(
        int.parse(match2.group(3)!),
        int.parse(match2.group(2)!),
        int.parse(match2.group(1)!),
      );
    }

    return null;
  }

  String _normalizeCurrency(String currency) {
    if (currency == '€') return 'EUR';
    if (currency == '\$') return 'USD';
    return currency.toUpperCase();
  }
}
