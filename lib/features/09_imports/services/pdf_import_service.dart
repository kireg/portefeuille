import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/boursorama_parser.dart';
import 'package:portefeuille/features/09_imports/services/csv/parsers/revolut_parser.dart';

class PdfImportService {
  final List<StatementParser> _parsers = [
    TradeRepublicParser(),
    BoursoramaParser(),
    RevolutParser(),
  ];
  
  Future<List<ParsedTransaction>> extractTransactions(File file) async {
    final List<ParsedTransaction> transactions = [];
    
    try {
      // Load the PDF document.
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text from all pages.
      String text = PdfTextExtractor(document).extractText();
      
      // Dispose the document.
      document.dispose();

      debugPrint("--- PDF CONTENT START ---");
      // Print text in chunks to avoid truncation
      const int chunkSize = 800;
      for (int i = 0; i < text.length; i += chunkSize) {
        int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
        debugPrint(text.substring(i, end));
      }
      debugPrint("--- PDF CONTENT END ---");

      // Find the right parser
      for (final parser in _parsers) {
        debugPrint("Testing parser: ${parser.bankName}");
        if (parser.canParse(text)) {
          debugPrint("Parser MATCHED: ${parser.bankName}");
          transactions.addAll(parser.parse(text));
          break;
        } else {
          debugPrint("Parser REJECTED: ${parser.bankName}");
        }
      }
      
      if (transactions.isEmpty) {
        debugPrint("No parser matched or no transactions found.");
      } else {
        debugPrint("--- PARSED TRANSACTIONS (${transactions.length}) ---");
        for (var t in transactions) {
          debugPrint(t.toString());
        }
        debugPrint("--- END TRANSACTIONS ---");
      }
      
    } catch (e) {
      debugPrint('Error extracting PDF: $e');
    }
    
    return transactions;
  }
}
