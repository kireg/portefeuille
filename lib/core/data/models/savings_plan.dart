// lib/core/data/models/savings_plan.dart

import 'package:hive/hive.dart';
import 'dart:math';

part 'savings_plan.g.dart';

@HiveType(typeId: 5)
class SavingsPlan {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  double monthlyAmount;
  @HiveField(3)
  String targetTicker;
  @HiveField(4)
  bool isActive;

  SavingsPlan({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.targetTicker,
    this.isActive = true,
  });

  // ... (toutes vos méthodes existantes : totalInvestedCapital, futureValue, etc. restent inchangées) ...

  double totalInvestedCapital(int years) {
    return monthlyAmount * 12 * years;
  }

  double futureValue(int years, double estimatedAnnualReturn) {
    if (monthlyAmount <= 0 || years <= 0) return 0;
    final monthlyRate = estimatedAnnualReturn / 12;
    final months = years * 12;
    if (monthlyRate == 0) {
      return monthlyAmount * months;
    }
    final futureVal = monthlyAmount * ((pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate);
    return futureVal;
  }

  double totalGain(int years, double estimatedAnnualReturn) {
    return futureValue(years, estimatedAnnualReturn) - totalInvestedCapital(years);
  }

  SavingsPlan deepCopy() {
    return SavingsPlan(
      id: id,
      name: name,
      monthlyAmount: monthlyAmount,
      targetTicker: targetTicker,
      isActive: isActive,
    );
  }

  // --- NOUVELLES MÉTHODES JSON ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'monthlyAmount': monthlyAmount,
      'targetTicker': targetTicker,
      'isActive': isActive,
    };
  }

  factory SavingsPlan.fromJson(Map<String, dynamic> json) {
    return SavingsPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
      targetTicker: json['targetTicker'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
// --- FIN NOUVELLES MÉTHODES JSON ---
}