import 'package:flutter/foundation.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

class RevolutParser implements StatementParser {
  @override
  String get bankName => "Revolut";

  @override
  bool canParse(String rawText) {
    // Revolut CSV usually starts with headers like "Type,Product,Started Date..."
    // Or "Date,Ticker,Type,Quantity..."
    // Since we receive rawText (which might be the CSV content), we check for headers.
    return rawText.contains("Type,Product,Started Date") || 
           rawText.contains("Date,Ticker,Type,Quantity") ||
           rawText.contains("Revolut");
  }

  @override
  String? get warningMessage => null;

  @override
  List<ParsedTransaction> parse(String rawText) {
    final List<ParsedTransaction> transactions = [];
    final lines = rawText.split('\n');
    
    if (lines.isEmpty) return transactions;

    // Detect format based on header
    final header = lines.first.trim();
    final isTradingFormat = header.contains("Date,Ticker,Type,Quantity");
    
    // Skip header
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      try {
        if (isTradingFormat) {
          _parseTradingLine(line, transactions);
        } else {
          _parseStandardLine(line, transactions);
        }
      } catch (e) {
        debugPrint("Error parsing Revolut line: $line -> $e");
      }
    }

    return transactions;
  }

  void _parseTradingLine(String line, List<ParsedTransaction> transactions) {
    // Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
    final parts = line.split(',');
    if (parts.length < 7) return;

    final dateStr = parts[0];
    final ticker = parts[1];
    final typeStr = parts[2];
    final quantityStr = parts[3];
    final priceStr = parts[4];
    final totalAmountStr = parts[5];
    final currency = parts[6];

    final date = DateTime.tryParse(dateStr);
    if (date == null) return;

    final quantity = double.tryParse(quantityStr);
    final price = double.tryParse(priceStr);
    final totalAmount = double.tryParse(totalAmountStr); // Usually negative for buy

    TransactionType type;
    if (typeStr == 'BUY') {
      type = TransactionType.Buy;
    } else if (typeStr == 'SELL') {
      type = TransactionType.Sell;
    } else if (typeStr == 'DIVIDEND') {
      type = TransactionType.Dividend;
    } else {
      return; // Ignore other types
    }

    transactions.add(ParsedTransaction(
      date: date,
      type: type,
      assetName: ticker, // Revolut uses Ticker as name often
      ticker: ticker, // Also set ticker
      isin: null,
      quantity: quantity ?? 0.0,
      amount: totalAmount?.abs() ?? 0.0, 
      price: price ?? 0.0,
      currency: currency,
      fees: 0.0, 
      assetType: AssetType.Stock,
    ));
  }

  void _parseStandardLine(String line, List<ParsedTransaction> transactions) {
    // Type,Product,Started Date,Completed Date,Description,Amount,Fee,Currency,State,Balance
    // Implementation skipped for now as Trading format is priority.
  }
}
