import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';
import 'package:portefeuille/features/09_imports/services/csv/parsers/revolut_parser.dart';

class CsvImportService {
  final List<StatementParser> _parsers = [
    RevolutParser(),
  ];
  
  Future<List<ParsedTransaction>> extractTransactions(File file) async {
    final List<ParsedTransaction> transactions = [];
    
    try {
      // Read CSV file
      final String text = await file.readAsString();

      debugPrint("--- CSV CONTENT START ---");
      debugPrint(text.substring(0, text.length > 500 ? 500 : text.length)); // Print first 500 chars
      debugPrint("--- CSV CONTENT END ---");

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
      }
      
    } catch (e) {
      debugPrint('Error extracting CSV: $e');
    }
    
    return transactions;
  }
}
