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
    // Supporte les avis d'opéré, les relevés de compte titres et les dividendes
    // BoursoBank est le nouveau nom de Boursorama Banque
    final isBourso = lower.contains("boursorama") || lower.contains("boursobank");
    return isBourso && 
           (lower.contains("avis d'opéré") || 
            lower.contains("relevé de compte") ||
            lower.contains("releve compte titres") ||
            lower.contains("dividende") ||
            lower.contains("coupon"));
  }

  @override
  String? get warningMessage => null;

  /// Détecte si le document est un relevé de portefeuille (snapshot)
  bool _isPortfolioStatement(String rawText) {
    final lower = rawText.toLowerCase();
    return lower.contains("releve compte titres") || 
           lower.contains("valorisé au") ||
           lower.contains("valorisation de la ligne");
  }

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
    // Si c'est un relevé de portefeuille, utiliser le parser dédié
    if (_isPortfolioStatement(rawText)) {
      return _parsePortfolioStatement(rawText);
    }
    
    // Sinon, parser les avis d'opéré classiques
    return _parseTradeConfirmations(rawText);
  }

  /// Parse un relevé de portefeuille (snapshot des positions)
  List<ParsedTransaction> _parsePortfolioStatement(String rawText) {
    final List<ParsedTransaction> transactions = [];
    
    // Extraction de la date de valorisation: "Valorisé au 30/09/2025"
    DateTime? docDate;
    final regexValoDate = RegExp(r'[Vv]aloris[eé]\s+au\s+(\d{2})/(\d{2})/(\d{4})');
    final dateMatch = regexValoDate.firstMatch(rawText);
    if (dateMatch != null) {
      docDate = DateTime(
        int.parse(dateMatch.group(3)!),
        int.parse(dateMatch.group(2)!),
        int.parse(dateMatch.group(1)!),
      );
    }
    
    // Pattern pour les lignes d'actifs dans le relevé BoursoBank
    // Le format PDF extrait peut être très compact (sans espaces) ou avec espaces.
    // 
    // Format compact: "15THALES (FR0000121329) * 266,603 999,0054,64163,88"
    // Format espacé: "15 THALES (FR0000121329) * 266,60 3 999,00 54,64 163,88"
    //
    // Structure: Qty + Name + (ISIN) + * + Prix + Valorisation + %Portef + PRU
    //
    // On cherche d'abord l'ISIN qui est le point d'ancrage le plus fiable
    final regexIsin = RegExp(r'\(([A-Z]{2}[A-Z0-9]{10})\)\s*\*');
    
    // Convertir tous les matches en liste pour pouvoir accéder aux indices
    final allIsinMatches = regexIsin.allMatches(rawText).toList();
    
    for (int i = 0; i < allIsinMatches.length; i++) {
      try {
        final isinMatch = allIsinMatches[i];
        final isin = isinMatch.group(1)!;
        final isinStart = isinMatch.start;
        
        // Chercher en arrière pour trouver quantité + nom
        // Déterminer le début de recherche : soit le précédent ISIN, soit max 200 caractères avant
        int prefixStart;
        if (i > 0) {
          // Commencer juste après le précédent ISIN
          prefixStart = allIsinMatches[i - 1].end;
        } else {
          // Premier ISIN : chercher depuis début de section ou 200 chars avant
          prefixStart = (isinStart - 200).clamp(0, rawText.length);
        }
        
        var prefix = rawText.substring(prefixStart, isinStart);
        
        // Dans les relevés BoursoBank, chaque section de positions commence par "ACTIONS"
        // puis suit le format: nombreNOM_ACTIF (ISIN)
        // Pour éviter de capturer les nombres de la ligne précédente (qui sont collés),
        // on cherche depuis le dernier mot-clé "ACTIONS", "EUR" ou autres marqueurs de section
        final sectionMarkers = ['ACTIONS', 'OBLIGATIONS', 'OPCVM', 'EUR', 'USD', 'GBP'];
        int bestMarkerPos = -1;
        for (final marker in sectionMarkers) {
          final pos = prefix.lastIndexOf(marker);
          if (pos > bestMarkerPos) {
            bestMarkerPos = pos;
          }
        }
        
        if (bestMarkerPos >= 0) {
          // Commencer la recherche après le marqueur
          prefix = prefix.substring(bestMarkerPos);
        }
        
        // Nouvelle stratégie: 
        // 1. Chercher le nom de l'actif qui précède l'ISIN (séquence de lettres majuscules)
        // 2. La quantité est le nombre immédiatement AVANT le nom (peut être collé)
        //
        // Format: "163,8810SOCIETE GENERALE" -> on veut "10" (collé à SOCIETE)
        // Format: "15THALES" -> on veut "15" (collé à THALES)
        // Format: "20 AM.MS" -> on veut "20" (espace avant AM)
        //
        // Problème: "8810" est capturé au lieu de "10" car c'est la séquence complète avant "S"
        // Solution: Heuristique - si qty > 1000 et précédé d'une virgule, prendre 2 derniers chiffres
        
        // Pattern: nombre (entier ou décimal) + nom en majuscules
        // Capture:
        // 1. Quantité (ex: "15", "2,5", "163,8810")
        // 2. Nom de l'actif
        final qtyNamePattern = RegExp(r'(\d+(?:[.,]\d+)?)\s*([A-ZÀ-Ü][A-ZÀ-Ü0-9\s\.&\-]+?)\s*$');
        final prefixMatch = qtyNamePattern.firstMatch(prefix);
        
        if (prefixMatch == null) {
          debugPrint('BoursoramaParser: Could not parse quantity+name for ISIN $isin: "$prefix"');
          continue;
        }
        
        var quantityStr = prefixMatch.group(1)!;
        final assetName = prefixMatch.group(2)!.trim();
        
        // Heuristique anti-collage et gestion des décimales
        // Cas 1: "163,8810" -> Prix "163,88" collé à Qty "10"
        // Cas 2: "2,5" -> Qty "2.5"
        // Cas 3: "15" -> Qty "15"
        
        double quantity = 0.0;
        
        if (quantityStr.contains(',') || quantityStr.contains('.')) {
          // Séparer partie entière et décimale
          final separator = quantityStr.contains(',') ? ',' : '.';
          final parts = quantityStr.split(separator);
          final decimals = parts[1];
          
          // Si plus de 2 décimales, c'est probablement une concaténation (Prix + Qty)
          // Car les prix ont généralement 2 décimales (EUR)
          if (decimals.length > 2) {
             // Ex: "8810" (4 chars) -> prendre "10" (2 derniers)
             // Ex: "072" (3 chars) -> prendre "2" (1 dernier)
             final takeCount = decimals.length >= 4 ? 2 : 1;
             final realQtyStr = decimals.substring(decimals.length - takeCount);
             quantity = double.tryParse(realQtyStr) ?? 0.0;
             
             debugPrint('BoursoramaParser: Applied anti-concatenation heuristic for $assetName: $quantityStr -> $quantity');
          } else {
            // C'est une vraie quantité décimale (ex: "2,5" ou "2,50")
            quantity = double.tryParse(quantityStr.replaceAll(',', '.')) ?? 0.0;
          }
        } else {
          // Entier simple
          quantity = double.tryParse(quantityStr) ?? 0.0;
        }
        
        // Chercher après l'ISIN pour le PRU (Prix de Revient Unitaire)
        final suffixStart = isinMatch.end;
        final suffixEnd = (suffixStart + 150).clamp(0, rawText.length);
        var suffix = rawText.substring(suffixStart, suffixEnd);
        
        // Nettoyer le suffix: arrêter avant le prochain ISIN, "Sous-Total", ou saut de section
        final stopPatterns = [
          RegExp(r'\([A-Z]{2}[A-Z0-9]{10}\)'), // Prochain ISIN
          RegExp(r'Sous-Total', caseSensitive: false),
          RegExp(r'TOTAL', caseSensitive: false),
          RegExp(r'VALEURS', caseSensitive: false),
        ];
        for (final pattern in stopPatterns) {
          final match = pattern.firstMatch(suffix);
          if (match != null && match.start > 0) {
            suffix = suffix.substring(0, match.start);
            break;
          }
        }

        if (quantity <= 0) {
          debugPrint('BoursoramaParser: Invalid quantity $quantityStr for $assetName');
          continue;
        }
        
        // 2. PRU: dernier nombre à 2 décimales dans le suffix
        final allDecimalMatches = RegExp(r'(\d+,\d{2})').allMatches(suffix).toList();
        var pru = 0.0;
        if (allDecimalMatches.isNotEmpty) {
          // Prendre le dernier (c'est toujours le PRU)
          pru = _parseNumber(allDecimalMatches.last.group(1)!);
        }
        
        if (pru <= 0) {
          debugPrint('BoursoramaParser: Could not determine PRU for ISIN $isin in: "$suffix"');
          continue;
        }
        
        // Calculer le montant investi basé sur le PRU (achat => montant négatif)
        final investedAmount = -(quantity * pru).abs();
        
        transactions.add(ParsedTransaction(
          date: docDate ?? DateTime.now(),
          type: TransactionType.Buy,
          assetName: assetName,
          isin: isin,
          ticker: isin, // Utiliser l'ISIN comme ticker pour grouper les transactions
          quantity: quantity,
          price: pru, // On utilise le PRU comme prix d'achat
          amount: investedAmount,
          fees: 0.0,
          currency: 'EUR',
          assetType: _inferAssetType(assetName),
        ));
        
        debugPrint('BoursoramaParser: Parsed position - $assetName ($isin), qty: $quantity, pru: $pru');
      } catch (e) {
        debugPrint('BoursoramaParser: Error parsing position: $e');
      }
    }
    
    return transactions;
  }

  /// Parse un nombre avec gestion des espaces comme séparateurs de milliers
  double _parseNumber(String str) {
    // Supprime les espaces (séparateurs de milliers) et remplace la virgule par un point
    final cleaned = str.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Parse les avis d'opéré (confirmations de transactions)
  Future<List<ParsedTransaction>> _parseTradeConfirmations(String rawText) async {
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
        var amount = quantity * price;
        // Uniformisation des signes: Achat négatif, Vente positif
        if (typeStr == 'achat') {
          amount = -amount.abs();
        } else {
          amount = amount.abs();
        }

        // Chercher un ISIN dans le bloc de texte entourant cette transaction
        String? isin;
        final isinRegex = RegExp(r'([A-Z]{2}[A-Z0-9]{9}[0-9])');
        final isinMatch = isinRegex.firstMatch(rawText);
        if (isinMatch != null) {
          isin = isinMatch.group(1);
        }

        transactions.add(ParsedTransaction(
          date: docDate ?? DateTime.now(),
          type: typeStr == 'achat' ? TransactionType.Buy : TransactionType.Sell,
          assetName: assetName,
          isin: isin,
          ticker: isin ?? assetName.replaceAll(RegExp(r'\s+'), '_').toUpperCase(), // Utiliser ISIN si disponible, sinon le nom
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
          ticker: assetName.replaceAll(RegExp(r'\s+'), '_').toUpperCase(), // Utiliser le nom comme ticker pour grouper
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
          ticker: assetName.replaceAll(RegExp(r'\s+'), '_').toUpperCase(), // Utiliser le nom comme ticker pour grouper
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
