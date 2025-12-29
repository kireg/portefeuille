import 'package:flutter/foundation.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

class RevolutParser implements StatementParser {
  static final RegExp _currencyRegex = RegExp(r'[A-Z]{3}');

  @override
  String get bankName => "Revolut";

  @override
  bool canParse(String rawText) {
    final lower = rawText.toLowerCase();
    return lower.contains("date,ticker,type,quantity") ||
        lower.contains("date,ticker,type,price per share") ||
        lower.contains("cash top-up") ||
        lower.contains("revolut");
  }

  @override
  String? get warningMessage => null;

  @override
  Future<List<ParsedTransaction>> parse(String rawText, {void Function(double)? onProgress}) async {
    final List<ParsedTransaction> transactions = [];
    final lines = rawText.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return transactions;

    for (var i = 0; i < lines.length; i++) {
      if (onProgress != null && i % 50 == 0) {
        onProgress(i / lines.length);
        await Future.delayed(Duration.zero);
      }

      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = _splitLine(line);
      if (_isHeader(parts)) continue;

      try {
        final parsed = _parseTradingLine(parts);
        if (parsed != null) {
          transactions.add(parsed);
        }
      } catch (e) {
        debugPrint("Error parsing Revolut line: $line -> $e");
      }
    }

    return transactions;
  }

  ParsedTransaction? _parseTradingLine(List<String> parts) {
    // Expected: Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
    if (parts.length < 3) return null;

    final date = DateTime.tryParse(parts[0].trim());
    if (date == null) return null;

    final ticker = _emptyToNull(parts.length > 1 ? parts[1].trim() : null);
    final typeStr = parts.length > 2 ? parts[2].trim() : '';
    final quantity = _parseNumber(parts.length > 3 ? parts[3] : null) ?? 0.0;
    final price = _parseNumber(parts.length > 4 ? parts[4] : null) ?? 0.0;
    final totalAmountStr = parts.length > 5 ? parts[5] : '';
    final amount = _parseNumber(totalAmountStr)?.abs() ?? 0.0;
    final currency = _resolveCurrency(parts, totalAmountStr) ?? 'EUR';

    final upperType = typeStr.toUpperCase();

    if (upperType.startsWith('BUY')) {
      return _buildTransaction(
        date: date,
        type: TransactionType.Buy,
        assetName: ticker,
        ticker: ticker,
        quantity: quantity,
        price: price,
        amount: -amount, // Négatif : sortie d'argent
        currency: currency,
        assetType: AssetType.Stock,
      );
    }

    if (upperType.startsWith('SELL')) {
      return _buildTransaction(
        date: date,
        type: TransactionType.Sell,
        assetName: ticker,
        ticker: ticker,
        quantity: quantity,
        price: price,
        amount: amount,
        currency: currency,
        assetType: AssetType.Stock,
      );
    }

    if (upperType.startsWith('DIVIDEND TAX')) {
      return _buildTransaction(
        date: date,
        type: TransactionType.Fees,
        assetName: ticker ?? 'Dividend tax',
        ticker: ticker,
        quantity: 0,
        price: 0,
        amount: amount,
        currency: currency,
        assetType: AssetType.Cash,
      );
    }

    if (upperType == 'DIVIDEND') {
      return _buildTransaction(
        date: date,
        type: TransactionType.Dividend,
        assetName: ticker ?? 'Dividende',
        ticker: ticker,
        quantity: 0,
        price: 0,
        amount: amount,
        currency: currency,
        assetType: AssetType.Stock,
      );
    }

    if (upperType.startsWith('CASH TOP-UP') ||
        upperType.startsWith('CASH TRANSFER') ||
        upperType.startsWith('CARD TOP-UP')) {
      return _buildTransaction(
        date: date,
        type: TransactionType.Deposit,
        assetName: 'Cash $currency'.trim(),
        ticker: null,
        quantity: 0,
        price: 1,
        amount: amount,
        currency: currency,
        assetType: AssetType.Cash,
      );
    }

    if (upperType.startsWith('CASH WITHDRAWAL')) {
      return _buildTransaction(
        date: date,
        type: TransactionType.Withdrawal,
        assetName: 'Cash $currency'.trim(),
        ticker: null,
        quantity: 0,
        price: 1,
        amount: -amount, // Négatif : sortie d'argent
        currency: currency,
        assetType: AssetType.Cash,
      );
    }

    if (upperType.startsWith('INTEREST')) {
      return _buildTransaction(
        date: date,
        type: TransactionType.Interest,
        assetName: ticker ?? 'Intérêt',
        ticker: ticker,
        quantity: 0,
        price: 0,
        amount: amount,
        currency: currency,
        assetType: AssetType.Cash,
      );
    }

    return null;
  }

  ParsedTransaction _buildTransaction({
    required DateTime date,
    required TransactionType type,
    required String? assetName,
    required String? ticker,
    required double quantity,
    required double price,
    required double amount,
    required String currency,
    required AssetType assetType,
  }) {
    final name = assetName?.isNotEmpty == true
        ? assetName!
        : ticker?.isNotEmpty == true
            ? ticker!
            : 'Inconnu';

    return ParsedTransaction(
      date: date,
      type: type,
      assetName: name,
      ticker: ticker,
      isin: null,
      quantity: quantity,
      amount: amount,
      price: price,
      currency: currency,
      fees: 0.0,
      assetType: assetType,
    );
  }

  List<String> _splitLine(String line) {
    return line.split(',').map((p) => p.trim()).toList();
  }

  bool _isHeader(List<String> parts) {
    if (parts.isEmpty) return true;
    final first = parts.first.toLowerCase();
    return first.startsWith('date') || first.startsWith('type');
  }

  double? _parseNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    var sanitized = value.replaceAll(RegExp(r'[^0-9,.-]'), '');
    final hasComma = sanitized.contains(',');
    final hasDot = sanitized.contains('.');

    if (hasComma && hasDot) {
      sanitized = sanitized.replaceAll(',', '');
    } else if (hasComma) {
      sanitized = sanitized.replaceAll(',', '.');
    }

    return double.tryParse(sanitized);
  }

  String? _resolveCurrency(List<String> parts, String amountPart) {
    if (parts.length > 6 && parts[6].trim().isNotEmpty) {
      return parts[6].trim();
    }

    final match = _currencyRegex.firstMatch(amountPart);
    return match?.group(0);
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
