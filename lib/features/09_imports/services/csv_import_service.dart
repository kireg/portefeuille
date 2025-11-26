import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';
import 'package:portefeuille/features/09_imports/services/csv/parsers/revolut_parser.dart';

class CsvImportService {
  final List<StatementParser> _parsers = [
    RevolutParser(),
  ];
  
  Future<List<ParsedTransaction>> extractTransactions(PlatformFile file) async {
    final List<ParsedTransaction> transactions = [];
    
    try {
      // Read CSV file
      String text;
      if (kIsWeb) {
        text = utf8.decode(file.bytes!);
      } else {
        text = await File(file.path!).readAsString();
      }

      debugPrint("--- CSV CONTENT START ---");
      debugPrint(text.substring(0, text.length > 500 ? 500 : text.length)); // Print first 500 chars
      debugPrint("--- CSV CONTENT END ---");

      // Find the right parser
      for (final parser in _parsers) {
        debugPrint("Testing parser: ${parser.bankName}");
        if (parser.canParse(text)) {
          debugPrint("Parser MATCHED: ${parser.bankName}");
          transactions.addAll(await parser.parse(text));
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
