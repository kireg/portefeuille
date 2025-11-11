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
    List<Account>? accounts,
  }) : accounts = accounts ?? [];

  double get totalValue {
    return accounts.fold(0.0, (sum, account) => sum + account.totalValue);
  }

  double get profitAndLoss {
    return accounts.fold(0.0, (sum, account) => sum + account.profitAndLoss);
  }

  // NOUVEAU : Capital investi total
  double get totalInvestedCapital {
    return accounts.fold(
        0.0, (sum, account) => sum + account.totalInvestedCapital);
  }

  // CORRIGÉ : Formule correcte basée sur le capital investi
  double get profitAndLossPercentage {
    final capitalInvested = totalInvestedCapital;

    // Si aucun capital investi, pas de P/L
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
      id: id, // MIS À JOUR
      name: name,
      accounts: accounts.map((account) => account.deepCopy()).toList(),
    );
  }
}
