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
  final String id; // NOUVEAU

  Institution({
    required this.id, // MIS À JOUR
    required this.name,
    this.accounts = const [],
  });

  double get totalValue {
    return accounts.fold(0.0, (sum, account) => sum + account.totalValue);
  }

  double get profitAndLoss {
    return accounts.fold(0.0, (sum, account) => sum + account.profitAndLoss);
  }

  double get profitAndLossPercentage {
    final totalPnl = profitAndLoss;
    final currentValue = totalValue;
    if (currentValue == totalPnl) {
      return 0;
    }
    final previousValue = currentValue - totalPnl;
    // Éviter la division par zéro si la valeur précédente était 0
    if (previousValue == 0) return 0.0;
    return totalPnl / previousValue;
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
      id: id, // MIS À JOUR
      name: name,
      accounts: accounts.map((account) => account.deepCopy()).toList(),
    );
  }
}