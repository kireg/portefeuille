import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:portefeuille/features/09_imports/services/csv/parsers/revolut_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/boursorama_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_account_statement_parser.dart';

/// Résultat de la détection de source.
class SourceDetectionResult {
  /// ID de la source détectée (null si non détectée).
  final String? sourceId;

  /// Niveau de confiance (0.0 à 1.0).
  final double confidence;

  /// Aperçu du contenu du fichier (premières lignes).
  final String preview;

  /// Texte brut extrait pour le parsing.
  final String rawText;

  /// Message d'information optionnel.
  final String? message;

  const SourceDetectionResult({
    this.sourceId,
    this.confidence = 0.0,
    this.preview = '',
    this.rawText = '',
    this.message,
  });

  bool get isDetected => sourceId != null && confidence > 0.5;
}

/// Service de détection automatique de la source d'un fichier d'import.
class SourceDetector {
  /// Détecte la source d'un fichier et retourne un aperçu.
  Future<SourceDetectionResult> detect(PlatformFile file) async {
    try {
      final extension = file.extension?.toLowerCase() ?? '';

      // Cas spécial: La Première Brique (fichiers Excel avec structure spécifique)
      if (extension == 'xlsx' || extension == 'xls') {
        return await _detectExcelSource(file);
      }

      // Extraction du texte pour les autres formats
      final rawText = await _extractText(file);
      final preview = _generatePreview(rawText);

      // Test de chaque parser
      final detectionResults = <String, double>{};

      // Revolut
      if (RevolutParser().canParse(rawText)) {
        detectionResults['revolut'] = _calculateConfidence(rawText, [
          'date,ticker,type',
          'revolut',
          'cash top-up',
          'dividend',
        ]);
      }

      // Trade Republic Account Statement (priorité sur le parser générique)
      if (TradeRepublicAccountStatementParser().canParse(rawText)) {
        detectionResults['trade_republic'] = 0.95; // Haute confiance
      }
      // Trade Republic (générique)
      else if (TradeRepublicParser().canParse(rawText)) {
        detectionResults['trade_republic'] = 0.85;
      }

      // Boursorama
      if (BoursoramaParser().canParse(rawText)) {
        detectionResults['boursorama'] = _calculateConfidence(rawText, [
          'boursorama',
          "avis d'opéré",
          'achat au comptant',
          'vente au comptant',
        ]);
      }

      // Trouver la meilleure correspondance
      if (detectionResults.isEmpty) {
        return SourceDetectionResult(
          preview: preview,
          rawText: rawText,
          message: 'Aucune source reconnue automatiquement.',
        );
      }

      final bestMatch = detectionResults.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      return SourceDetectionResult(
        sourceId: bestMatch.key,
        confidence: bestMatch.value,
        preview: preview,
        rawText: rawText,
        message: 'Source détectée avec ${(bestMatch.value * 100).toInt()}% de confiance.',
      );
    } catch (e) {
      debugPrint('SourceDetector error: $e');
      return SourceDetectionResult(
        message: 'Erreur lors de l\'analyse: $e',
      );
    }
  }

  /// Détecte les sources Excel (La Première Brique).
  Future<SourceDetectionResult> _detectExcelSource(PlatformFile file) async {
    try {
      List<int> bytes;
      if (kIsWeb) {
        bytes = file.bytes!;
      } else {
        bytes = await File(file.path!).readAsBytes();
      }

      final excel = excel_lib.Excel.decodeBytes(bytes);
      final sheetNames = excel.tables.keys.map((k) => k.toLowerCase()).toList();

      // La Première Brique: cherche "Mes prêts" ou "Mes prets"
      if (sheetNames.any((name) => name.contains('prêts') || name.contains('prets'))) {
        final preview = _generateExcelPreview(excel);
        return SourceDetectionResult(
          sourceId: 'la_premiere_brique',
          confidence: 0.95,
          preview: preview,
          rawText: preview,
          message: 'Fichier La Première Brique détecté (feuille "Mes prêts" trouvée).',
        );
      }

      // Revolut XLSX: cherche les en-têtes caractéristiques
      final csvText = _excelToCsv(excel);
      if (RevolutParser().canParse(csvText)) {
        return SourceDetectionResult(
          sourceId: 'revolut',
          confidence: 0.90,
          preview: _generatePreview(csvText),
          rawText: csvText,
          message: 'Fichier Revolut détecté.',
        );
      }

      return SourceDetectionResult(
        preview: _generateExcelPreview(excel),
        rawText: csvText,
        message: 'Fichier Excel non reconnu.',
      );
    } catch (e) {
      return SourceDetectionResult(
        message: 'Erreur lors de l\'analyse Excel: $e',
      );
    }
  }

  /// Extrait le texte d'un fichier PDF ou CSV.
  Future<String> _extractText(PlatformFile file) async {
    final extension = file.extension?.toLowerCase();
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();

    if (extension == 'pdf') {
      final document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    }

    // CSV ou autre texte
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Génère un aperçu des premières lignes.
  String _generatePreview(String text, {int maxLines = 10, int maxChars = 500}) {
    final lines = text.split(RegExp(r'\r?\n'));
    final previewLines = lines.take(maxLines).toList();
    var preview = previewLines.join('\n');

    if (preview.length > maxChars) {
      preview = '${preview.substring(0, maxChars)}...';
    } else if (lines.length > maxLines) {
      preview += '\n...';
    }

    return preview;
  }

  /// Génère un aperçu pour un fichier Excel.
  String _generateExcelPreview(excel_lib.Excel excel) {
    final buffer = StringBuffer();
    
    for (final tableName in excel.tables.keys.take(2)) {
      buffer.writeln('📄 Feuille: $tableName');
      final sheet = excel.tables[tableName]!;
      
      for (int i = 0; i < sheet.maxRows && i < 5; i++) {
        final row = sheet.row(i);
        final cells = row.map((cell) {
          final value = cell?.value;
          if (value == null) return '';
          return value.toString();
        }).take(5).toList();
        buffer.writeln('  ${cells.join(' | ')}');
      }
      
      if (sheet.maxRows > 5) {
        buffer.writeln('  ... (+${sheet.maxRows - 5} lignes)');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Convertit un Excel en texte CSV.
  String _excelToCsv(excel_lib.Excel excel) {
    if (excel.tables.isEmpty) return '';

    final buffer = StringBuffer();
    final sheet = excel.tables.values.first;

    for (final row in sheet.rows) {
      final cells = row.map((cell) {
        final value = cell?.value;
        if (value == null) return '';
        if (value is excel_lib.TextCellValue) return value.value.toString();
        if (value is excel_lib.DateCellValue) {
          return DateTime(value.year, value.month, value.day).toIso8601String();
        }
        return value.toString();
      }).toList();

      if (cells.every((v) => v.trim().isEmpty)) continue;
      buffer.writeln(cells.join(','));
    }

    return buffer.toString();
  }

  /// Calcule un score de confiance basé sur les mots-clés trouvés.
  double _calculateConfidence(String text, List<String> keywords) {
    final lower = text.toLowerCase();
    int matches = 0;

    for (final keyword in keywords) {
      if (lower.contains(keyword.toLowerCase())) {
        matches++;
      }
    }

    return (matches / keywords.length).clamp(0.5, 1.0);
  }
}
