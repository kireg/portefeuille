// lib/core/data/models/transaction.dart

import 'package:hive/hive.dart';
import 'package:portefeuille/core/utils/enum_helpers.dart'; // NOUVEL IMPORT
import 'transaction_type.dart';
import 'asset_type.dart';

part 'transaction.g.dart';

@HiveType(typeId: 7)
class Transaction {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String accountId;

  @HiveField(2)
  final TransactionType type;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? assetTicker;

  @HiveField(5)
  final String? assetName;

  @HiveField(6)
  final double? quantity;

  @HiveField(7)
  final double? price;

  @HiveField(8)
  final double amount;

  @HiveField(9)
  final double fees;

  @HiveField(10)
  final String notes;

  @HiveField(11)
  final AssetType? assetType;

  @HiveField(12)
  final String? priceCurrency;

  @HiveField(13)
  final double? exchangeRate;

  Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.date,
    required this.amount,
    this.assetTicker,
    this.assetName,
    this.quantity,
    this.price,
    this.priceCurrency,
    this.exchangeRate,
    this.fees = 0.0,
    this.notes = '',
    this.assetType,
  });

  double get totalAmount {
    return amount - fees;
  }

  // --- NOUVELLES MÉTHODES JSON ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'type': enumToString(type),
      'date': date.toIso8601String(),
      'assetTicker': assetTicker,
      'assetName': assetName,
      'quantity': quantity,
      'price': price,
      'amount': amount,
      'fees': fees,
      'notes': notes,
      'assetType': enumToString(assetType),
      'priceCurrency': priceCurrency,
      'exchangeRate': exchangeRate,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      type: enumFromString(
        TransactionType.values,
        json['type'],
        fallback: TransactionType.Deposit,
      ),
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      assetTicker: json['assetTicker'] as String?,
      assetName: json['assetName'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      fees: (json['fees'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
      assetType: enumFromString(
        AssetType.values,
        json['assetType'],
        fallback: AssetType.Other,
      ),
      priceCurrency: json['priceCurrency'] as String?,
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
    );
  }
// --- FIN NOUVELLES MÉTHODES JSON ---
}