// lib/core/data/models/institution.dart

import 'package:hive/hive.dart';
import 'account.dart';

part 'institution.g.dart';

@HiveType(typeId: 1)
class Institution {
  @HiveField(0)
  final String name;

  @HiveField(1)
  List<Account> accounts;

  @HiveField(2)
  final String id;

  Institution({
    required this.id,
    required this.name,
    List<Account>? accounts,
  }) : accounts = accounts ?? [];

  // ... (tous vos getters existants : totalValue, profitAndLoss, etc. restent inchangés) ...

  double get totalValue {
    return accounts.fold(0.0, (sum, account) => sum + account.totalValue);
  }

  double get profitAndLoss {
    return accounts.fold(0.0, (sum, account) => sum + account.profitAndLoss);
  }

  double get totalInvestedCapital {
    return accounts.fold(
        0.0, (sum, account) => sum + account.totalInvestedCapital);
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
    final weightedYield = accounts.fold(
        0.0, (sum, acc) => sum + (acc.totalValue * acc.estimatedAnnualYield));
    return weightedYield / totalVal;
  }

  Institution deepCopy() {
    return Institution(
      id: id,
      name: name,
      accounts: accounts.map((account) => account.deepCopy()).toList(),
    );
  }

  // --- NOUVELLES MÉTHODES JSON ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accounts': accounts.map((acc) => acc.toJson()).toList(),
    };
  }

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'] as String,
      name: json['name'] as String,
      accounts: (json['accounts'] as List<dynamic>? ?? [])
          .map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
// --- FIN NOUVELLES MÉTHODES JSON ---

  Institution copyWith({
    String? id,
    String? name,
    List<Account>? accounts,
  }) {
    return Institution(
      id: id ?? this.id,
      name: name ?? this.name,
      accounts: accounts ?? this.accounts,
    );
  }
}