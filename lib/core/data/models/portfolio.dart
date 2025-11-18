// lib/core/data/models/portfolio.dart

import 'package:hive/hive.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';

part 'portfolio.g.dart';

@HiveType(typeId: 0)
class Portfolio {
  @HiveField(0)
  List<Institution> institutions;

  @HiveField(1)
  final String id;

  @HiveField(2)
  String name;

  @HiveField(3)
  List<SavingsPlan> savingsPlans;

  Portfolio({
    required this.id,
    required this.name,
    List<Institution>? institutions,
    List<SavingsPlan>? savingsPlans,
  })  : institutions = institutions ?? [],
        savingsPlans = savingsPlans ?? [];

  // ... (tous vos getters existants : totalValue, profitAndLoss, etc. restent inchangés) ...

  double get totalValue {
    return institutions.fold(0.0, (sum, inst) => sum + inst.totalValue);
  }

  double get profitAndLoss {
    return institutions.fold(0.0, (sum, inst) => sum + inst.profitAndLoss);
  }

  double get totalInvestedCapital {
    return institutions.fold(
        0.0, (sum, inst) => sum + inst.totalInvestedCapital);
  }

  double get profitAndLossPercentage {
    final capitalInvested = totalInvestedCapital;
    if (capitalInvested == 0) {
      return 0.0;
    }
    final totalPnl = profitAndLoss;
    return totalPnl / capitalInvested;
  }

  double get estimatedAnnualYield {
    final totalVal = totalValue;
    if (totalVal == 0) {
      return 0.0;
    }
    final weightedYield = institutions.fold(0.0,
            (sum, inst) => sum + (inst.totalValue * inst.estimatedAnnualYield));
    return weightedYield / totalVal;
  }

  Portfolio deepCopy() {
    return Portfolio(
      id: id,
      name: name,
      institutions: institutions.map((inst) => inst.deepCopy()).toList(),
      savingsPlans: savingsPlans.map((plan) => plan.deepCopy()).toList(),
    );
  }

  // --- NOUVELLES MÉTHODES JSON ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'institutions': institutions.map((inst) => inst.toJson()).toList(),
      'savingsPlans': savingsPlans.map((plan) => plan.toJson()).toList(),
    };
  }

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'] as String,
      name: json['name'] as String,
      institutions: (json['institutions'] as List<dynamic>? ?? [])
          .map((e) => Institution.fromJson(e as Map<String, dynamic>))
          .toList(),
      savingsPlans: (json['savingsPlans'] as List<dynamic>? ?? [])
          .map((e) => SavingsPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
// --- FIN NOUVELLES MÉTHODES JSON ---
}