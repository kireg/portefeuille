// lib/core/data/models/portfolio.dart

import 'package:hive/hive.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio_value_history_point.dart';
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

  @HiveField(4)
  List<PortfolioValueHistoryPoint> valueHistory;

  Portfolio({
    required this.id,
    required this.name,
    List<Institution>? institutions,
    List<SavingsPlan>? savingsPlans,
    List<PortfolioValueHistoryPoint>? valueHistory,
  })  : institutions = institutions ?? [],
        savingsPlans = savingsPlans ?? [],
        valueHistory = valueHistory ?? [];

  double get totalValue {
    return institutions.fold(0.0, (sum, inst) => sum + inst.totalValue);
  }

  // ... (Vos autres getters existants: profitAndLoss, etc. restent inchangés) ...
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

  /// Ajoute ou met à jour un point d'historique pour la date d'aujourd'hui.
  /// Retourne true si une modification a eu lieu.
  bool addOrUpdateHistoryPoint(double value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Chercher si un point existe déjà pour aujourd'hui
    final index = valueHistory.indexWhere((p) {
      final pDate = DateTime(p.date.year, p.date.month, p.date.day);
      return pDate.isAtSameMomentAs(today);
    });

    if (index != -1) {
      // Mise à jour si la valeur a changé significativement (> 0.01)
      if ((valueHistory[index].value - value).abs() > 0.01) {
        valueHistory[index] = PortfolioValueHistoryPoint(date: now, value: value);
        return true;
      }
      return false;
    } else {
      // Nouveau point
      valueHistory.add(PortfolioValueHistoryPoint(date: now, value: value));
      // On garde la liste triée par date
      valueHistory.sort((a, b) => a.date.compareTo(b.date));
      return true;
    }
  }

  Portfolio deepCopy() {
    return Portfolio(
      id: id,
      name: name,
      institutions: institutions.map((inst) => inst.deepCopy()).toList(),
      savingsPlans: savingsPlans.map((plan) => plan.deepCopy()).toList(),
      valueHistory: valueHistory.map((e) => PortfolioValueHistoryPoint(date: e.date, value: e.value)).toList(),
    );
  }

  // ... (Méthodes JSON existantes) ...
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'institutions': institutions.map((inst) => inst.toJson()).toList(),
      'savingsPlans': savingsPlans.map((plan) => plan.toJson()).toList(),
      'valueHistory': valueHistory.map((e) => e.toJson()).toList(),
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
      valueHistory: (json['valueHistory'] as List<dynamic>? ?? [])
          .map((e) => PortfolioValueHistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}