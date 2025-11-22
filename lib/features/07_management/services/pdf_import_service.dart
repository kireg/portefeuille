import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';

class ImportedTransaction {
  final DateTime date;
  final String type; // BUY, SELL, DIVIDEND
  final String ticker;
  final double amount;
  final double quantity;
  final double price;
  final String currency;

  ImportedTransaction({
    required this.date,
    required this.type,
    required this.ticker,
    required this.amount,
    required this.quantity,
    required this.price,
    required this.currency,
  });
  
  @override
  String toString() => '$type $ticker: $quantity @ $price ($amount $currency) on $date';
}

class PdfImportService {
  
  Future<List<ImportedTransaction>> extractTransactions(File file) async {
    final List<ImportedTransaction> transactions = [];
    
    try {
      // Load the PDF document.
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text from all pages.
      // Note: extractText() might merge lines. extractTextLines() is better if available, 
      // but Syncfusion extractText returns a string.
      String text = PdfTextExtractor(document).extractText();
      
      // Dispose the document.
      document.dispose();

      debugPrint("PDF Content extracted (first 100 chars): ${text.substring(0, text.length > 100 ? 100 : text.length)}");

      // Parse the text
      if (text.contains('Trade Republic')) {
        transactions.addAll(_parseTradeRepublic(text));
      } else {
        // Try generic parsing
        transactions.addAll(_parseGeneric(text));
      }
      
    } catch (e) {
      debugPrint('Error extracting PDF: $e');
    }
    
    return transactions;
  }

  List<ImportedTransaction> _parseTradeRepublic(String text) {
    // TODO: Implement Trade Republic parsing logic
    // Trade Republic PDFs often have "Ordre de marché Achat" or "Market Order Buy"
    // and lines like "10,0000 Int.  150,00 EUR"
    return [];
  }

  List<ImportedTransaction> _parseGeneric(String text) {
    // Generic parser looking for patterns
    // This is a placeholder.
    return [];
  }
}
