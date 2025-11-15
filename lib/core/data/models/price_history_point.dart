// lib/core/data/models/price_history_point.dart
import 'package:hive/hive.dart';

part 'price_history_point.g.dart';

@HiveType(typeId: 10) // <-- ID NON UTILISÉ
class PriceHistoryPoint {
  /// Ticker de l'actif
  @HiveField(0)
  final String ticker;

  /// Date (tronquée au jour)
  @HiveField(1)
  final DateTime date;

  /// Prix de clôture ce jour-là
  @HiveField(2)
  final double price;

  /// Devise du prix (ex: "USD", "EUR")
  @HiveField(3)
  final String currency;

  PriceHistoryPoint({
    required this.ticker,
    required this.date,
    required this.price,
    required this.currency,
  });
}