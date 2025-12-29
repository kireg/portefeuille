import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' as excel_lib hide Border;
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/boursorama_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_account_statement_parser.dart';
import 'package:portefeuille/features/09_imports/services/csv/parsers/revolut_parser.dart';
import 'package:portefeuille/features/09_imports/services/excel/la_premiere_brique_parser.dart';
import 'package:portefeuille/features/09_imports/services/models/import_category.dart';
import 'package:portefeuille/features/09_imports/services/source_detector.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/ui/screens/file_import_wizard/wizard_state.dart';

/// Service gérant le parsing des fichiers d'import.
/// 
/// Supporte les formats :
/// - PDF (Boursorama, Trade Republic)
/// - CSV (Revolut)
/// - Excel (La Première Brique)
class WizardParsingService {
  final SourceDetector sourceDetector = SourceDetector();

  /// Détecte automatiquement la source du fichier.
  Future<SourceDetectionResult> detectSource(PlatformFile file) async {
    return await sourceDetector.detect(file);
  }

  /// Parse le fichier selon la source sélectionnée.
  /// 
  /// [file] : Le fichier à parser
  /// [sourceId] : L'identifiant de la source (boursorama, revolut, etc.)
  /// [state] : L'état du wizard (sera mis à jour avec les métadonnées crowdfunding)
  /// [trCategory] : La catégorie Trade Republic (CTO ou PEA)
  /// [existingTransactions] : Les transactions existantes pour la détection de doublons
  /// [importMode] : Le mode d'import (initial ou update)
  /// [onProgress] : Callback de progression
  Future<ImportDiffResult> parseFile({
    required PlatformFile file,
    required String sourceId,
    required WizardState state,
    required ImportCategory trCategory,
    required List<Transaction> existingTransactions,
    required dynamic importMode,
    void Function(double)? onProgress,
  }) async {
    List<ParsedTransaction> results = [];
    String? parserWarning;

    if (sourceId == 'la_premiere_brique') {
      results = await _parseCrowdfunding(file, state);
    } else {
      final textResult = await _parseTextBasedSource(
        file: file,
        sourceId: sourceId,
        trCategory: trCategory,
        onProgress: onProgress,
      );
      results = textResult.transactions;
      parserWarning = textResult.warning;
    }

    state.parserWarning = parserWarning;

    return ImportDiffService().compute(
      parsed: results,
      existing: existingTransactions,
      mode: importMode,
    );
  }

  /// Parse un fichier crowdfunding La Première Brique.
  Future<List<ParsedTransaction>> _parseCrowdfunding(
    PlatformFile file,
    WizardState state,
  ) async {
    final parser = LaPremiereBriqueParser();
    final projects = await parser.parse(file);
    state.crowdfundingMetadata = {};

    return projects.map((p) {
      final ticker = p.projectName;

      state.crowdfundingMetadata[ticker] = AssetMetadata(
        ticker: ticker,
        projectName: p.projectName,
        minDuration: p.minDurationMonths,
        targetDuration: p.durationMonths,
        maxDuration: p.maxDurationMonths,
        expectedYield: p.yieldPercent,
        repaymentType: p.repaymentType,
        priceCurrency: 'EUR',
      );

      return ParsedTransaction(
        date: p.investmentDate ?? DateTime.now(),
        type: TransactionType.Buy,
        assetName: p.projectName,
        ticker: ticker,
        quantity: p.investedAmount,
        price: 1.0,
        amount: -p.investedAmount,
        fees: 0,
        currency: 'EUR',
        assetType: AssetType.RealEstateCrowdfunding,
      );
    }).toList();
  }

  /// Parse un fichier texte (PDF ou CSV).
  Future<_TextParseResult> _parseTextBasedSource({
    required PlatformFile file,
    required String sourceId,
    required ImportCategory trCategory,
    void Function(double)? onProgress,
  }) async {
    final text = await _extractText(file);
    StatementParser? parser;

    switch (sourceId) {
      case 'boursorama':
        parser = BoursoramaParser();
        break;
      case 'revolut':
        parser = RevolutParser();
        break;
      case 'trade_republic':
        final trSnapshotParser = TradeRepublicParser();
        final trStatementParser = TradeRepublicAccountStatementParser();
        parser = trStatementParser.canParse(text)
            ? trStatementParser
            : trSnapshotParser;
        break;
    }

    if (parser == null) {
      return _TextParseResult(transactions: [], warning: null);
    }

    final results = await parser.parse(text, onProgress: onProgress);
    
    // Filtrage par catégorie Trade Republic si applicable
    final filtered = sourceId == 'trade_republic'
        ? results.where((p) => p.category == null || p.category == trCategory).toList()
        : results;

    return _TextParseResult(
      transactions: filtered,
      warning: parser.warningMessage,
    );
  }

  /// Extrait le texte d'un fichier (PDF, CSV ou Excel).
  Future<String> _extractText(PlatformFile file) async {
    final extension = file.extension?.toLowerCase();

    if (extension == 'pdf') {
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    }

    final bytes = file.bytes ?? await File(file.path!).readAsBytes();

    if (extension == 'xlsx' || extension == 'xls') {
      try {
        final excel = excel_lib.Excel.decodeBytes(bytes);
        if (excel.tables.isEmpty) return '';

        final buffer = StringBuffer();
        final sheet = excel.tables.values.first;

        for (final row in sheet.rows) {
          final cells = row.map(_stringifyCell).toList();
          if (cells.every((value) => value.trim().isEmpty)) continue;
          buffer.writeln(cells.join(','));
        }

        return buffer.toString();
      } on FormatException {
        return utf8.decode(bytes, allowMalformed: true);
      }
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  String _stringifyCell(excel_lib.Data? cell) {
    final value = cell?.value;
    if (value == null) return '';

    if (value is excel_lib.TextCellValue) return value.value.toString();
    if (value is excel_lib.DateCellValue) {
      return DateTime(value.year, value.month, value.day).toIso8601String();
    }

    return value.toString();
  }
}

/// Résultat d'un parsing texte.
class _TextParseResult {
  final List<ParsedTransaction> transactions;
  final String? warning;

  _TextParseResult({required this.transactions, this.warning});
}

/// Collecte les transactions existantes d'un portfolio.
List<Transaction> collectExistingTransactions(PortfolioProvider provider) {
  final portfolio = provider.activePortfolio;
  if (portfolio == null) return [];

  final transactions = <Transaction>[];
  for (final inst in portfolio.institutions) {
    for (final acc in inst.accounts) {
      transactions.addAll(acc.transactions);
    }
  }
  return transactions;
}
