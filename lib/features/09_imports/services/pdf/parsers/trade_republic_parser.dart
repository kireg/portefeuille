import 'package:flutter/foundation.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/09_imports/services/models/import_category.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

class TradeRepublicParser implements StatementParser {
  @override
  String get bankName => "Trade Republic";

  @override
  bool canParse(String rawText) {
    final canParse = rawText.contains("Trade Republic Bank GmbH") ||
        rawText.contains("TRADE REPUBLIC");
    debugPrint("TradeRepublicParser.canParse: $canParse");
    return canParse;
  }

  @override
  String? get warningMessage =>
      "Ce document n'est pas l'historique de toutes vos transactions mais l'image à l'instant t de ce que vous possédez, il peut fausser l'analyse de vos plus values.";

  AssetType _inferAssetType(String name) {
    final upper = name.toUpperCase();
    if (upper.contains('ETF') ||
        upper.contains('MSCI') ||
        upper.contains('S&P') ||
        upper.contains('VANGUARD') ||
        upper.contains('ISHARES') ||
        upper.contains('AMUNDI')) {
      return AssetType.ETF;
    }
    if (upper.contains('COIN') ||
        upper.contains('BITCOIN') ||
        upper.contains('ETHEREUM') ||
        upper.contains('BTC') ||
        upper.contains('ETH') ||
        upper.contains('SOLANA')) {
      return AssetType.Crypto;
    }
    return AssetType.Stock;
  }

  @override
  Future<List<ParsedTransaction>> parse(String rawText,
      {void Function(double)? onProgress}) async {
    final List<ParsedTransaction> transactions = [];

    // Normalisation du texte : remplacer les sauts de ligne par des espaces pour faciliter les regex
    // Mais attention, parfois la structure ligne par ligne est utile.
    // On va essayer de parser ligne par ligne ou par blocs.

    // Regex générique pour un achat/vente standard chez TR (Format approximatif, à affiner avec de vrais exemples)
    // Ex: "Achat de 10 titres Apple Inc. au cours de 150,00 EUR"
    // Ex: "Market Order Buy 10.5 shares Tesla Inc. at 200.00 USD"

    // Pattern 1 : Achat/Vente classique (Français)
    // "Achat de 4,1234 titres Nom de l'actif au cours de 123,45 EUR"
    // NOTE: On utilise [\s\S]*? pour le nom de l'actif car il peut contenir des espaces ou des sauts de ligne
    final regexOrderFR = RegExp(
      r'(Achat|Vente)\s+de\s+([\d,]+)\s+titres\s+([\s\S]*?)\s+au\s+cours\s+de\s+([\d,]+)\s+(EUR|USD)',
      caseSensitive: false,
    );

    // Pattern 2 : Dividende (Français) - Version améliorée
    // Format 1: "Dividende pour 10 titres Apple Inc. Montant par titre 0,25 USD Total 2,50 USD"
    // Format 2: "Dividende Apple Inc. 2,50 EUR"
    // Format 3: Bloc avec "Dividende" puis lignes suivantes avec montant
    final regexDividendFR = RegExp(
      r'Dividende\s+pour\s+([\d,]+)\s+titres\s+([\s\S]*?)\s+Montant\s+par\s+titre\s+([\d,]+)\s*(EUR|USD)',
      caseSensitive: false,
    );

    // Pattern alternatif pour dividendes avec montant total direct
    final regexDividendAlt = RegExp(
      r'Dividende\s+([\s\S]*?)\s+Total[:\s]+([\d,]+)\s*(EUR|USD)',
      caseSensitive: false,
    );

    // Pattern pour "Crédit" qui indique souvent le montant net reçu après un dividende
    final regexCreditAmount = RegExp(
      r'Crédit[:\s]+([\d,]+)\s*(EUR|USD)',
      caseSensitive: false,
    );

    // Pattern 3 : Relevé de positions (Portfolio)
    // "22,00 titre(s) ... ISIN : FR... ... 19,28 21/11/2025 424,25"
    // Capture: 1=Qty, 2=Name, 3=ISIN, 4=Price, 5=Date, 6=Total
    final regexPosition = RegExp(
      r'([\d,]+)\s+titre\(s\)\s+([\s\S]*?)\s+ISIN\s*:\s*([A-Z0-9]+)[\s\S]*?([\d,]+)\s+(\d{2}/\d{2}/\d{4})\s+([\d,]+)',
      caseSensitive: false,
    );

    // Extraction des dates (souvent en haut du document : "Date : 12.05.2023")
    final regexDate = RegExp(r'Date\s*[:.]?\s*(\d{2})[./](\d{2})[./](\d{4})');
    DateTime? docDate;
    final dateMatch = regexDate.firstMatch(rawText);
    if (dateMatch != null) {
      docDate = DateTime(
        int.parse(dateMatch.group(3)!),
        int.parse(dateMatch.group(2)!),
        int.parse(dateMatch.group(1)!),
      );
      debugPrint("TradeRepublicParser: Date found: $docDate");
    } else {
      // Fallback pour le relevé de positions qui a la date dans le titre "au 21/11/2025"
      final regexDateTitle = RegExp(r'au\s+(\d{2})/(\d{2})/(\d{4})');
      final dateTitleMatch = regexDateTitle.firstMatch(rawText);
      if (dateTitleMatch != null) {
        docDate = DateTime(
          int.parse(dateTitleMatch.group(3)!),
          int.parse(dateTitleMatch.group(2)!),
          int.parse(dateTitleMatch.group(1)!),
        );
        debugPrint("TradeRepublicParser: Date found in title: $docDate");
      } else {
        debugPrint("TradeRepublicParser: No date found");
      }
    }

    // Recherche des correspondances pour les ordres
    final matches = regexOrderFR.allMatches(rawText);
    debugPrint("TradeRepublicParser: Found ${matches.length} order matches");

    for (final match in matches) {
      final typeStr = match.group(1)!.toLowerCase();
      final qtyStr = match.group(2)!.replaceAll(',', '.');
      final assetName = match.group(3)!.trim();
      final priceStr = match.group(4)!.replaceAll(',', '.');
      final currency = match.group(5)!;

      final quantity = double.tryParse(qtyStr) ?? 0.0;
      final price = double.tryParse(priceStr) ?? 0.0;
        // Uniformisation: Achat = montant négatif, Vente = positif
        final rawAmount = quantity * price;
        final amount = (typeStr == 'achat') ? -rawAmount.abs() : rawAmount.abs();
      final assetType = _inferAssetType(assetName);
      final ImportCategory? category = assetType == AssetType.Crypto
          ? ImportCategory.crypto
          : ImportCategory.unknown;

      transactions.add(ParsedTransaction(
        date: docDate ?? DateTime.now(), // Fallback si date non trouvée
        type: typeStr == 'achat' ? TransactionType.Buy : TransactionType.Sell,
        assetName: assetName,
        quantity: quantity,
        price: price,
        amount: amount,
        fees: 1.0, // TR a souvent 1€ de frais, mais c'est une supposition
        currency: currency,
        assetType: assetType,
        category: category,
      ));
      debugPrint(
          "TradeRepublicParser: Added transaction: $typeStr $quantity $assetName @ $price $currency");
    }

    // Recherche des positions (Import initial)
    final positionMatches = regexPosition.allMatches(rawText);
    debugPrint(
        "TradeRepublicParser: Found ${positionMatches.length} position matches");

    for (final match in positionMatches) {
      final qtyStr = match.group(1)!.replaceAll(',', '.');
      final assetNameRaw = match.group(2)!.trim();
      // Nettoyage du nom (enlève les sauts de ligne excessifs)
      final assetName = assetNameRaw.replaceAll(RegExp(r'\s+'), ' ');

      final isin = match.group(3)!;
      final priceStr = match.group(4)!.replaceAll(',', '.');
      // Group 5 is date, we can use it or docDate
      final totalStr = match.group(6)!.replaceAll(',', '.');

      final quantity = double.tryParse(qtyStr) ?? 0.0;
      final price = double.tryParse(priceStr) ?? 0.0;
      final total = double.tryParse(totalStr) ?? 0.0;
      final assetType = _inferAssetType(assetName);
      final ImportCategory? category = assetType == AssetType.Crypto
          ? ImportCategory.crypto
          : ImportCategory.unknown;

      transactions.add(ParsedTransaction(
        date: docDate ?? DateTime.now(),
        type: TransactionType.Buy, // Portfolio snapshot
        assetName: assetName,
        isin: isin,
        quantity: quantity,
        price: price,
        amount: -total.abs(),
        fees: 0.0,
        currency: "EUR", // Par défaut EUR sur ce relevé
        assetType: assetType,
        category: category,
      ));
      debugPrint(
          "TradeRepublicParser: Added position: $quantity $assetName ($isin) @ $price");
    }

    // Recherche des dividendes
    final dividendMatches = regexDividendFR.allMatches(rawText);
    debugPrint(
        "TradeRepublicParser: Found ${dividendMatches.length} dividend matches");

    for (final match in dividendMatches) {
      try {
        final qtyStr = match.group(1)!.replaceAll(',', '.');
        final assetName = match.group(2)!.trim().replaceAll(RegExp(r'\s+'), ' ');
        final perShareStr = match.group(3)!.replaceAll(',', '.');
        final currency = match.group(4)!;

        final quantity = double.tryParse(qtyStr) ?? 0.0;
        final perShare = double.tryParse(perShareStr) ?? 0.0;
        final amount = (quantity * perShare).abs(); // Dividende toujours positif

        final assetType = _inferAssetType(assetName);
        final ImportCategory? category = assetType == AssetType.Crypto
            ? ImportCategory.crypto
            : ImportCategory.unknown;

        transactions.add(ParsedTransaction(
          date: docDate ?? DateTime.now(),
          type: TransactionType.Dividend,
          assetName: assetName,
          quantity: quantity,
          price: perShare,
          amount: amount,
          fees: 0,
          currency: currency,
          assetType: assetType,
          category: category,
        ));
        debugPrint("TradeRepublicParser: Added dividend: $assetName amount=$amount $currency");
      } catch (e) {
        debugPrint('TradeRepublicParser: Error parsing dividend: $e');
      }
    }

    // Recherche des dividendes avec format alternatif (montant total direct)
    final dividendAltMatches = regexDividendAlt.allMatches(rawText);
    debugPrint(
        "TradeRepublicParser: Found ${dividendAltMatches.length} dividend alt matches");

    for (final match in dividendAltMatches) {
      try {
        final assetName = match.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
        final amountStr = match.group(2)!.replaceAll(',', '.');
        final currency = match.group(3)!;

        final amount = double.tryParse(amountStr) ?? 0.0;

        // Vérifier qu'on n'a pas déjà ajouté ce dividende
        final alreadyExists = transactions.any((t) =>
            t.type == TransactionType.Dividend &&
            t.assetName.contains(assetName.substring(0, assetName.length > 10 ? 10 : assetName.length)));
        
        if (!alreadyExists) {
          final assetType = _inferAssetType(assetName);
          final ImportCategory? category = assetType == AssetType.Crypto
              ? ImportCategory.crypto
              : ImportCategory.unknown;

          transactions.add(ParsedTransaction(
            date: docDate ?? DateTime.now(),
            type: TransactionType.Dividend,
            assetName: assetName,
            quantity: 0,
            price: 0,
            amount: amount,
            fees: 0,
            currency: currency,
            assetType: assetType,
            category: category,
          ));
          debugPrint("TradeRepublicParser: Added dividend (alt): $assetName amount=$amount $currency");
        }
      } catch (e) {
        debugPrint('TradeRepublicParser: Error parsing dividend alt: $e');
      }
    }

    // Si on a trouvé un crédit mais pas de montant de dividende, on met à jour
    final creditMatch = regexCreditAmount.firstMatch(rawText);
    if (creditMatch != null) {
      final creditAmountStr = creditMatch.group(1)!.replaceAll(',', '.');
      final creditCurrency = creditMatch.group(2)!;
      final creditAmount = double.tryParse(creditAmountStr) ?? 0.0;

      // Met à jour le dernier dividende sans montant
      final dividendIdx = transactions.lastIndexWhere(
          (t) => t.type == TransactionType.Dividend && t.amount == 0);
      if (dividendIdx >= 0) {
        final tx = transactions[dividendIdx];
        transactions[dividendIdx] = ParsedTransaction(
          date: tx.date,
          type: tx.type,
          assetName: tx.assetName,
          isin: tx.isin,
          ticker: tx.ticker,
          quantity: tx.quantity,
          price: tx.price,
          amount: creditAmount,
          fees: tx.fees,
          currency: creditCurrency,
          assetType: tx.assetType,
          category: tx.category,
        );
        debugPrint("TradeRepublicParser: Updated dividend with credit amount: $creditAmount $creditCurrency");
      }
    }

    return transactions;
  }
}
