import 'package:hive/hive.dart';
import 'institution.dart';

part 'portfolio.g.dart';

@HiveType(typeId: 0)
class Portfolio extends HiveObject {
  @HiveField(0)
  List<Institution> institutions;

  Portfolio({this.institutions = const []});

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

    // Si la valeur actuelle est égale à la P/L, le coût de base était de 0
    // (par exemple, un dépôt initial qui a seulement gagné de la valeur)
    if (currentValue == totalPnl) {
      return totalPnl > 0 ? double.infinity : 0; // Évite la division par 0
    }

    final previousValue = currentValue - totalPnl;

    // Si la valeur précédente était 0, on ne peut pas calculer de %
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
    final weightedYield = institutions.fold(0.0, (sum, inst) => sum + (inst.totalValue * inst.estimatedAnnualYield));
    return weightedYield / totalVal;
  }

  Portfolio deepCopy() {
    return Portfolio(
      institutions: institutions.map((inst) => inst.deepCopy()).toList(),
    );
  }
}