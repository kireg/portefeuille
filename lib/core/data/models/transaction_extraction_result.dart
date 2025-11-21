import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

class TransactionExtractionResult {
  final DateTime? date;
  final double? amount;
  final double? quantity;
  final double? price;
  final double? fees;
  final String? ticker;
  final String? name;
  final TransactionType? type;
  final String? currency;
  final AssetType? assetType;

  TransactionExtractionResult({
    this.date,
    this.amount,
    this.quantity,
    this.price,
    this.fees,
    this.ticker,
    this.name,
    this.type,
    this.currency,
    this.assetType,
  });

  factory TransactionExtractionResult.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les dates au format YYYY-MM-DD
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    // Helper pour mapper les strings de l'IA vers les Enums
    TransactionType? parseType(String? typeStr) {
      if (typeStr == null) return null;
      switch (typeStr.toUpperCase()) {
        case 'BUY': return TransactionType.Buy;
        case 'SELL': return TransactionType.Sell;
        case 'DIVIDEND': return TransactionType.Dividend;
        case 'DEPOSIT': return TransactionType.Deposit;
        case 'WITHDRAWAL': return TransactionType.Withdrawal;
        case 'FEES': return TransactionType.Fees;
        case 'INTEREST': return TransactionType.Interest;
        default: return null;
      }
    }

    // On nettoie les montants (parfois l'IA renvoie "1 200.50")
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value.replaceAll(RegExp(r'[^\d.-]'), ''));
      }
      return null;
    }

    return TransactionExtractionResult(
      date: parseDate(json['date']),
      amount: parseDouble(json['amount']),
      quantity: parseDouble(json['quantity']),
      price: parseDouble(json['price']),
      fees: parseDouble(json['fees']),
      ticker: json['ticker'],
      name: json['assetName'],
      type: parseType(json['type']),
      currency: json['currency'],
      assetType: json['assetType'] == 'ETF' || json['assetType'] == 'STOCK'
          ? AssetType.Stock
          : AssetType.Other, // Simplification pour l'exemple
    );
  }
}