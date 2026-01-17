import 'package:flutter/foundation.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/models/import_category.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

class TradeRepublicAccountStatementParser implements StatementParser {
  @override
  String get bankName => "Trade Republic (Relevé de Compte)";

  @override
  bool canParse(String rawText) {
    // Check for specific keywords that identify the Account Statement (Relevé de Compte)
    // vs the Securities Account Statement (Relevé de Titres)
    return rawText.contains("TRADE REPUBLIC") &&
        (rawText.contains("SYNTHÈSE DU RELEVÉ DE COMPTE") ||
            rawText.contains("ACCOUNT STATEMENT SUMMARY"));
  }

  @override
  String? get warningMessage =>
      null; // This is the "good" parser, no warning needed.

  @override
  Future<List<ParsedTransaction>> parse(String rawText,
      {void Function(double)? onProgress}) async {
    debugPrint("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("🔍 DÉBUT DU PARSING - Trade Republic Account Statement");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

    final List<ParsedTransaction> transactions = [];
    // Par défaut on traite la section en cours comme CTO ; chaque section "Compte PEA"
    // bascule dynamiquement la catégorie non-crypto vers PEA.
    ImportCategory currentCategory = ImportCategory.cto;
    debugPrint("📁 Catégorie initiale : ${currentCategory.name.toUpperCase()}");

    // 1. Pre-processing: Split into lines
    final lines = rawText.split('\n').map((l) => l.trim()).toList();

    // 2. State Machine to parse transactions
    // We look for a date at the start of a line to begin a transaction block.
    // We accumulate lines until the next date or end of file.

    List<String> currentBlock = [];

    // Regex for date: "01 mai 2025" or "01 May 2025"
    // French months: janv, févr, mars, avr, mai, juin, juil, août, sept, oct, nov, déc
    // We'll use a regex that matches DD MMM YYYY
    final dateRegex = RegExp(r'^\d{2}\s+[a-zA-Zéû\.]+\s+\d{4}');

    // Regex for split date:
    // Line i: \d{2}
    // Line i+1: [a-zA-Zéû\.]+
    // Line i+2: \d{4}
    final dayRegex = RegExp(r'^\d{2}$');
    final monthRegex = RegExp(r'^[a-zA-Zéû\.]+$');
    final yearRegex = RegExp(r'^\d{4}$');

    bool inTransactionsSection = false;

    for (int i = 0; i < lines.length; i++) {
      // Report progress
      if (onProgress != null && i % 50 == 0) {
        onProgress(i / lines.length);
        // Allow UI to update
        await Future.delayed(Duration.zero);
      }

      final line = lines[i];
      final lowerLine = line.toLowerCase();

      // Changement de section selon l'intitulé du produit
      if (lowerLine.contains('compte pea')) {
        debugPrint("\n🏦 CHANGEMENT DE SECTION DÉTECTÉ : COMPTE PEA");
        debugPrint("   Ligne : $line");
        if (currentBlock.isNotEmpty) {
          debugPrint(
              "   ⚠️  Traitement du bloc en cours avant changement de section...");
          _parseBlock(currentBlock, transactions, currentCategory);
          currentBlock = [];
        }
        currentCategory = ImportCategory.pea;
        debugPrint(
            "   ✅ Catégorie changée : ${currentCategory.name.toUpperCase()}\n");
        inTransactionsSection = false;
        continue;
      }
      if (lowerLine.contains('compte courant') ||
          lowerLine.contains('compte espèces') ||
          lowerLine.contains('compte espece')) {
        debugPrint(
            "\n🏦 CHANGEMENT DE SECTION DÉTECTÉ : COMPTE COURANT/ESPÈCES");
        debugPrint("   Ligne : $line");
        if (currentBlock.isNotEmpty) {
          debugPrint(
              "   ⚠️  Traitement du bloc en cours avant changement de section...");
          _parseBlock(currentBlock, transactions, currentCategory);
          currentBlock = [];
        }
        currentCategory = ImportCategory.cto;
        debugPrint(
            "   ✅ Catégorie changée : ${currentCategory.name.toUpperCase()}\n");
        inTransactionsSection = false;
        continue;
      }

      // Nouvelle synthèse : on réinitialise avant de chercher le prochain tableau "TRANSACTIONS".
      if (line.contains("SYNTHÈSE DU RELEVÉ DE COMPTE") ||
          line.contains("ACCOUNT STATEMENT SUMMARY")) {
        debugPrint("\n📋 NOUVELLE SYNTHÈSE DÉTECTÉE");
        debugPrint("   Ligne : $line");
        if (currentBlock.isNotEmpty) {
          debugPrint(
              "   ⚠️  Traitement du bloc en cours avant nouvelle synthèse...");
          _parseBlock(currentBlock, transactions, currentCategory);
          currentBlock = [];
        }
        inTransactionsSection = false;
        debugPrint("   ✅ Section transactions désactivée\n");
        continue;
      }

      // Detect start of transactions section
      if (line.contains("TRANSACTIONS") &&
          (i + 1 < lines.length && lines[i + 1].contains("DATE"))) {
        debugPrint("\n📊 SECTION TRANSACTIONS DÉTECTÉE");
        debugPrint("   Ligne actuelle : $line");
        debugPrint("   Ligne suivante : ${lines[i + 1]}");
        debugPrint(
            "   Catégorie active : ${currentCategory.name.toUpperCase()}");
        inTransactionsSection = true;
        debugPrint("   ✅ Analyse des transactions activée\n");
        continue;
      }

      // Skip headers/footers if possible, but the date check usually handles it.
      if (!inTransactionsSection) continue;

      // Check if line starts with a date (Single line format)
      bool isNewTransaction = false;
      bool isSplitDate = false;

      if (dateRegex.hasMatch(line)) {
        isNewTransaction = true;
      }
      // Check for split date format
      else if (i + 2 < lines.length &&
          dayRegex.hasMatch(line) &&
          monthRegex.hasMatch(lines[i + 1]) &&
          yearRegex.hasMatch(lines[i + 2])) {
        isNewTransaction = true;
        isSplitDate = true;
      }

      if (isNewTransaction) {
        // Process previous block if exists
        // IMPORTANT: Only process if we are in the transactions section
        if (currentBlock.isNotEmpty && inTransactionsSection) {
          debugPrint(
              "\n💳 Traitement du bloc précédent (${currentBlock.length} lignes)");
          _parseBlock(currentBlock, transactions, currentCategory);
          currentBlock = [];
        }

        // Only start a new block if we are in the transactions section
        if (inTransactionsSection) {
          if (isSplitDate) {
            // Reconstruct date on one line
            final dateStr = "${lines[i]} ${lines[i + 1]} ${lines[i + 2]}";
            debugPrint("\n📅 Nouvelle transaction (date split) : $dateStr");
            currentBlock.add(dateStr);
            i += 2; // Skip next 2 lines as they are part of the date
          } else {
            debugPrint("\n📅 Nouvelle transaction : $line");
            currentBlock.add(line);
          }
        } else {
          // Skip dates before the TRANSACTIONS section header
          if (isSplitDate) {
            i += 2; // Still skip the date parts to avoid misparse
          }
        }
      } else {
        // Append to current block if we are inside a transaction
        if (currentBlock.isNotEmpty) {
          // Filter out page numbers or repeated headers if they appear in the middle
          if (!line.contains("TRADE REPUBLIC BANK GMBH") &&
              !line.startsWith("Page")) {
            currentBlock.add(line);
          }
        }
      }
    }

    // Process last block
    if (currentBlock.isNotEmpty) {
      debugPrint(
          "\n💳 Traitement du dernier bloc (${currentBlock.length} lignes)");
      _parseBlock(currentBlock, transactions, currentCategory);
    }

    debugPrint("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint(
        "✅ FIN DU PARSING - ${transactions.length} transaction(s) extraite(s)");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

    return transactions;
  }

  void _parseBlock(
    List<String> block,
    List<ParsedTransaction> transactions,
    ImportCategory accountCategory,
  ) {
    if (block.isEmpty) return;

    debugPrint("\n   ┌─ ANALYSE DU BLOC ─────────────────────────────────");
    debugPrint("   │ Catégorie : ${accountCategory.name.toUpperCase()}");
    debugPrint("   │ Nombre de lignes : ${block.length}");
    debugPrint("   │ Contenu brut :");
    for (var i = 0; i < block.length; i++) {
      debugPrint("   │   [$i] ${block[i]}");
    }
    debugPrint("   └───────────────────────────────────────────────────");

    // Join block to analyze content more easily, but keep structure in mind.
    // Structure is usually:
    // Line 1: DATE
    // Line 2: TYPE
    // Line 3+: DESCRIPTION
    // Last Lines: AMOUNTS (Entry, Exit, Balance)

    // Example Block:
    // 02 mai 2025
    // Exécution d'ordre
    // Savings plan execution XF000BTC0017 Bitcoin, quantity: 0.000113
    // 9,97 €
    // 9597,19 €

    try {
      final dateStr = block[0]; // "02 mai 2025"
      final date = _parseDate(dateStr);

      // Type is usually on the second line, but sometimes date and type are on same line in raw text extraction?
      // Based on the file provided, it seems they are on separate lines.
      // Let's assume line 1 is date.

      // We need to find the amounts at the end.
      // Amounts are like "9,97 €" or "1 234,56 €"
      // We look from the end of the block.

      // Helper to parse amount string "1 234,56 €" -> 1234.56
      double? parseAmount(String s) {
        if (!s.contains('€')) return null;
        final clean = s
            .replaceAll('€', '')
            .replaceAll(' ', '')
            .replaceAll(',', '.')
            .trim();
        return double.tryParse(clean);
      }

      // The last line is usually Balance (Solde).
      // The line before could be Amount Out or Amount In.
      // Or both are on the same line? In the text file, they seem to be on separate lines or columns.
      // In the extracted text:
      // 9,97 €
      // 9597,19 €
      // It seems the columns are flattened.

      // Let's iterate backwards to find amounts.
      for (int i = block.length - 1; i >= 0; i--) {
        if (block[i].contains('€')) {
          // This is likely the balance or an amount.
          // The last one is Balance.
          // The one before is the transaction amount.
          break;
        }
      }

      // If we found the balance, look for the transaction amount before it.
      // Note: Sometimes Balance is not present or parsed differently.
      // But in the example:
      // ...
      // 9,97 €  <-- Amount (Out)
      // 9597,19 € <-- Balance

      // Let's try to identify amounts.
      // We need to distinguish In vs Out.
      // The columns are: DATE | TYPE | DESCRIPTION | IN | OUT | BALANCE
      // In the text extraction, empty columns might be skipped.

      // Strategy: Parse all amounts at the end of the block.
      final List<double> amounts = [];
      int lastAmountLineIndex = -1;

      for (int i = block.length - 1; i >= 0; i--) {
        final val = parseAmount(block[i]);
        if (val != null) {
          amounts.add(val);
          lastAmountLineIndex = i;
        } else {
          // If we hit a non-amount line after finding amounts, we stop?
          // Be careful of numbers in description.
          if (amounts.isNotEmpty && i < lastAmountLineIndex - 1) break;
        }
      }

      // amounts are in reverse order: [Balance, AmountOut/In]
      // Example: [9597.19, 9.97]

      debugPrint("   │ 💶 Montants détectés : $amounts");

      double transactionAmount = 0.0;

      if (amounts.length >= 2) {
        transactionAmount =
            amounts[1]; // The second from last is the transaction amount
        debugPrint("   │    → Montant transaction : $transactionAmount");
        debugPrint("   │    → Solde : ${amounts[0]}");
        // How to know if it is IN or OUT?
        // We can check the column headers but that's hard in a block.
        // We can infer from Type.
      } else if (amounts.length == 1) {
        // Only one amount found? Maybe balance is missing or amount is missing.
        transactionAmount = amounts[0];
        debugPrint("   │    → Montant unique détecté : $transactionAmount");
      }

      // Parse Type and Description
      // Everything between Date and Amounts is Type + Description.
      // Usually Line 1 = Date
      // Line 2 = Type
      // Line 3..N = Description

      // In split format, Type might be split too.
      // We join everything from index 1 to lastAmountLineIndex.

      final int descEndIndex =
          lastAmountLineIndex > 0 ? lastAmountLineIndex : block.length;
      String fullDescription = "";

      if (1 < descEndIndex) {
        fullDescription = block.sublist(1, descEndIndex).join(" ");
      }

      // Clean up Type from Description
      // Known types: "Exécution d'ordre", "Intérêts créditeur", "Virement"
      final String typeStr = fullDescription; // For type detection
      String description = fullDescription;

      if (fullDescription.contains("Exécution d'ordre")) {
        description =
            fullDescription.replaceAll("Exécution d'ordre", "").trim();
      } else if (fullDescription.contains("Intérêts créditeur")) {
        description =
            fullDescription.replaceAll("Intérêts créditeur", "").trim();
      } else if (fullDescription.contains("Virement")) {
        // Keep Virement maybe?
      }

      // IMPORTANT: Détecter et IGNORER les virements inter-comptes (Versement PEA)
      // Ces virements sont des transferts internes entre compte courant et PEA
      // - Dans la section "Compte courant": Versement PEA = sortie vers PEA (à ignorer)
      // - Dans la section "Compte PEA": Versement PEA = entrée depuis compte courant (à ignorer)
      // On ne garde que les vrais dépôts externes (Incoming transfer, SEPA reçu, etc.)
      //
      // IMPORTANT: Également ignorer "Incoming transfer from" car ce sont des virements
      // depuis le compte courant vers le CTO (dépôts compensatoires automatiques)
      // L'application applique déjà ces dépôts compensatoires, donc on ne doit pas
      // les importer pour éviter la duplication.
      if (description.contains("Versement PEA") ||
          description.contains("Versement d'activation") ||
          fullDescription.contains("Versement PEA") ||
          fullDescription.contains("Activation PEA") ||
          description.contains("Incoming transfer from") ||
          fullDescription.contains("Incoming transfer from")) {
        // Skip internal transfers between accounts
        debugPrint("   │ ⚠️  TRANSFERT INTERNE IGNORÉ");
        debugPrint("   │    Description : $description");
        debugPrint("   └───────────────────────────────────────────────────");
        debugPrint("   ⏭️  Transaction ignorée (transfert inter-comptes)\n");
        return; // Ne pas ajouter cette transaction
      }

      // Determine TransactionType and AssetType
      TransactionType type = TransactionType.Deposit; // Default
      AssetType assetType = AssetType.Stock; // Default

      // Logic based on Type string and Description
      if (typeStr.contains("Exécution d'ordre") ||
          description.contains("Savings plan execution") ||
          description.contains("Market Order")) {
        // Buy or Sell
        // If we can't determine In/Out from columns, we assume Buy for "Savings plan" usually.
        // Or we check if "Achat" or "Vente" is in text.
        // "Savings plan execution" is typically a Buy.
        type = TransactionType.Buy;
        if (description.contains("Vente") || description.contains("Sell")) {
          type = TransactionType.Sell;
        }
      } else if (typeStr.contains("Intérêts") ||
          description.contains("interest")) {
        type = TransactionType.Dividend; // Or Interest
      } else if (typeStr.contains("Dividende") ||
          description.contains("Dividend")) {
        type = TransactionType.Dividend;
      } else if (typeStr.contains("Virement") ||
          description.contains("Transfer")) {
        // Check direction
        // If we don't have column info, it's hard.
        // But usually "Virement entrant" or "Virement sortant".
        type = TransactionType.Deposit;
      }

      // Refine Amount Direction if possible
      // In the text file, "ENTRÉE D'ARGENT" is column 4, "SORTIE D'ARGENT" is column 5.
      // But we lost column alignment.
      // However, we know:
      // Buy -> Out
      // Sell -> In
      // Dividend -> In
      // Interest -> In

      // Extract Quantity and ISIN from Description
      // "Savings plan execution XF000BTC0017 Bitcoin, quantity: 0.000113"
      String? isin;
      double quantity = 0.0;
      String? ticker;
      String assetName = description;

      final isinRegex = RegExp(r'([A-Z]{2}[A-Z0-9]{9}[0-9])');
      final qtyRegex = RegExp(r'quantity:\s*([0-9.]+)');

      final isinMatch = isinRegex.firstMatch(description);
      if (isinMatch != null) {
        isin = isinMatch.group(1);
        ticker =
            isin; // Utiliser l'ISIN comme ticker pour grouper les transactions
      }

      final qtyMatch = qtyRegex.firstMatch(description);
      if (qtyMatch != null) {
        quantity = double.tryParse(qtyMatch.group(1) ?? "0") ?? 0.0;
      }

      debugPrint("   │ 📝 Description complète : $fullDescription");
      debugPrint("   │ 🔖 ISIN : ${isin ?? 'NON DÉTECTÉ'}");
      debugPrint("   │ 🔢 Quantité : $quantity");

      // Clean Asset Name
      // Remove "Savings plan execution", ISIN, "quantity: ..."
      assetName = description
          .replaceAll("Savings plan execution", "")
          .replaceAll("Market Order", "")
          .replaceAll(isin ?? "", "")
          .replaceAll(RegExp(r'quantity:\s*[0-9.]+'), "")
          .trim();

      if (assetName.startsWith("-")) assetName = assetName.substring(1).trim();
      if (assetName.endsWith(",")) {
        assetName = assetName.substring(0, assetName.length - 1).trim();
      }
      if (assetName.isEmpty) assetName = "Unknown Asset";

      debugPrint("   │ 🏷️  Nom de l'actif : $assetName");

      // Infer Asset Type
      assetType = _inferAssetType(assetName, isin);
      debugPrint("   │ 📊 Type d'actif : ${assetType.name}");
      debugPrint("   │ 🔄 Type de transaction : ${type.name}");

      // Calculate Price
      double price = 0.0;
      if (quantity > 0) {
        price = (transactionAmount.abs()) / quantity;
        debugPrint("   │ 💰 Prix unitaire : ${price.toStringAsFixed(2)} €");
      }

      final blockLower = block.join(' ').toLowerCase();

      // Uniformisation des signes de montants
      double signedAmount = transactionAmount;
      switch (type) {
        case TransactionType.Buy:
          signedAmount = -transactionAmount.abs();
          break;
        case TransactionType.Sell:
          signedAmount = transactionAmount.abs();
          break;
        case TransactionType.Dividend:
        case TransactionType.Interest:
        case TransactionType.Deposit:
          signedAmount = transactionAmount.abs();
          break;
        case TransactionType.Withdrawal:
          signedAmount = -transactionAmount.abs();
          break;
        default:
          signedAmount = transactionAmount;
      }

      final finalCategory = assetType == AssetType.Crypto
          ? ImportCategory.crypto
          : (blockLower.contains('pea') ? ImportCategory.pea : accountCategory);

      debugPrint(
          "   │ 💵 Montant signé final : ${signedAmount.toStringAsFixed(2)} €");
      debugPrint(
          "   │ 🗂️  Catégorie finale : ${finalCategory.name.toUpperCase()}");
      debugPrint("   │ 📅 Date : ${date.day}/${date.month}/${date.year}");
      debugPrint("   └───────────────────────────────────────────────────");
      debugPrint("   ✅ Transaction ajoutée\n");

      transactions.add(ParsedTransaction(
        date: date,
        type: type,
        assetName: assetName,
        isin: isin,
        ticker: ticker,
        quantity: quantity,
        price: price,
        amount: signedAmount,
        fees:
            0, // Fees are often separate or included. In this summary, they might be included in net amount.
        currency: "EUR",
        assetType: assetType,
        category: finalCategory,
      ));
    } catch (e) {
      debugPrint("   │ ❌ ERREUR DE PARSING");
      debugPrint("   │ Erreur : $e");
      debugPrint("   │ Bloc complet :");
      for (var i = 0; i < block.length; i++) {
        debugPrint("   │   [$i] ${block[i]}");
      }
      debugPrint("   └───────────────────────────────────────────────────\n");
    }
  }

  DateTime _parseDate(String dateStr) {
    // "01 mai 2025"
    try {
      final parts = dateStr.split(' ');
      if (parts.length < 3) return DateTime.now();

      final day = int.parse(parts[0]);
      final monthStr = parts[1].toLowerCase().replaceAll('.', '');
      final year = int.parse(parts[2]);

      int month = 1;
      switch (monthStr) {
        case 'janv':
        case 'jan':
          month = 1;
          break;
        case 'févr':
        case 'fev':
        case 'février':
          month = 2;
          break;
        case 'mars':
          month = 3;
          break;
        case 'avr':
        case 'avril':
          month = 4;
          break;
        case 'mai':
          month = 5;
          break;
        case 'juin':
          month = 6;
          break;
        case 'juil':
        case 'juillet':
          month = 7;
          break;
        case 'août':
        case 'aout':
          month = 8;
          break;
        case 'sept':
          month = 9;
          break;
        case 'oct':
          month = 10;
          break;
        case 'nov':
          month = 11;
          break;
        case 'déc':
        case 'dec':
        case 'décembre':
          month = 12;
          break;
      }

      return DateTime(year, month, day);
    } catch (e) {
      return DateTime.now();
    }
  }

  AssetType _inferAssetType(String name, String? isin) {
    final upper = name.toUpperCase();
    final isinUpper = isin?.toUpperCase() ?? "";

    if (upper.contains('ETF') ||
        upper.contains('MSCI') ||
        upper.contains('S&P') ||
        upper.contains('VANGUARD') ||
        upper.contains('ISHARES') ||
        upper.contains('AMUNDI')) {
      return AssetType.ETF;
    }
    // Crypto ISINs often start with XF on Trade Republic? Or just names.
    if (upper.contains('BITCOIN') ||
        upper.contains('ETHEREUM') ||
        upper.contains('SOLANA') ||
        upper.contains('DOT') ||
        upper.contains('CRYPTO')) {
      return AssetType.Crypto;
    }
    if (isinUpper.startsWith("XF")) {
      // Often crypto trackers or crypto on TR
      return AssetType.Crypto;
    }

    return AssetType.Stock;
  }
}
