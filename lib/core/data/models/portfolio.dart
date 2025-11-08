import 'package:hive/hive.dart';
import 'package:portefeuille/core/data/models/institution.dart';
// N'oubliez pas l'import pour Uuid si vous l'utilisez ici,
// mais il est préférable de le générer à l'extérieur.

part 'portfolio.g.dart';

@HiveType(typeId: 0)
class Portfolio extends HiveObject {
  @HiveField(0)
  List<Institution> institutions;

  @HiveField(1)
  final String id; // NOUVEAU

  @HiveField(2)
  String name; // NOUVEAU

  Portfolio({
    required this.id,
    required this.name,
    this.institutions = const [],
  });

  double get totalValue {
    return institutions.fold(0.0, (sum, inst) => sum + inst.totalValue);
  }

  // NOUVEAU : Logique de P/L agrégée
  double get profitAndLoss {
    return institutions.fold(0.0, (sum, inst) => sum + inst.profitAndLoss);
  }

  // NOUVEAU : Logique de P/L en pourcentage
  double get profitAndLossPercentage {
    final totalPnl = profitAndLoss;
    final currentValue = totalValue;

    if (currentValue == totalPnl) {
      return totalPnl > 0 ? double.infinity : 0;
    }

    final previousValue = currentValue - totalPnl;
    if (previousValue == 0) {
      return 0.0;
    }

    return totalPnl / previousValue;
  }

  double get estimatedAnnualYield {
    final totalVal = totalValue;
    if (totalVal == 0) {
      return 0.0;
    }
    final weightedYield = institutions.fold(
        0.0, (sum, inst) => sum + (inst.totalValue * inst.estimatedAnnualYield));
    return weightedYield / totalVal;
  }

  Portfolio deepCopy() {
    return Portfolio(
      id: id, // MIS À JOUR
      name: name, // MIS À JOUR
      institutions: institutions.map((inst) => inst.deepCopy()).toList(),
    );
  }
}