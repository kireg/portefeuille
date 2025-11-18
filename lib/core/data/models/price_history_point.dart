// lib/core/data/models/price_history_point.dart
import 'package:hive/hive.dart';

part 'price_history_point.g.dart';

@HiveType(typeId: 10)
class PriceHistoryPoint {
  @HiveField(0)
  final String ticker;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String currency;

  PriceHistoryPoint({
    required this.ticker,
    required this.date,
    required this.price,
    required this.currency,
  });

  // --- NOUVELLES MÉTHODES JSON ---
  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'date': date.toIso8601String(),
      'price': price,
      'currency': currency,
    };
  }

  factory PriceHistoryPoint.fromJson(Map<String, dynamic> json) {
    return PriceHistoryPoint(
      ticker: json['ticker'] as String,
      date: DateTime.parse(json['date'] as String),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }
// --- FIN NOUVELLES MÉTHODES JSON ---
}