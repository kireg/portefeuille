// lib/core/data/models/exchange_rate_history.dart
import 'package:hive/hive.dart';

part 'exchange_rate_history.g.dart';

@HiveType(typeId: 11)
class ExchangeRateHistory {
  @HiveField(0)
  final String pair;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double rate;

  ExchangeRateHistory({
    required this.pair,
    required this.date,
    required this.rate,
  });

  // --- NOUVELLES MÉTHODES JSON ---
  Map<String, dynamic> toJson() {
    return {
      'pair': pair,
      'date': date.toIso8601String(),
      'rate': rate,
    };
  }

  factory ExchangeRateHistory.fromJson(Map<String, dynamic> json) {
    return ExchangeRateHistory(
      pair: json['pair'] as String,
      date: DateTime.parse(json['date'] as String),
      rate: (json['rate'] as num).toDouble(),
    );
  }
// --- FIN NOUVELLES MÉTHODES JSON ---
}