// lib/core/data/models/portfolio_value_history_point.dart
import 'package:hive/hive.dart';

part 'portfolio_value_history_point.g.dart';

@HiveType(typeId: 20) // Choisissez un typeId unique
class PortfolioValueHistoryPoint {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double value;

  PortfolioValueHistoryPoint({
    required this.date,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
    };
  }

  factory PortfolioValueHistoryPoint.fromJson(Map<String, dynamic> json) {
    return PortfolioValueHistoryPoint(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }
}
