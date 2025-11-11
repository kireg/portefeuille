// lib/core/data/models/portfolio.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:hive/hive.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
// N'oubliez pas l'import pour Uuid si vous l'utilisez ici,
// mais il est préférable de le générer à l'extérieur.
part 'portfolio.g.dart';

@HiveType(typeId: 0)
class Portfolio {
  @HiveField(0)
  List<Institution> institutions;

  @HiveField(1)
  final String id;
  // NOUVEAU

  @HiveField(2)
  String name; // NOUVEAU

  @HiveField(3)
  List<SavingsPlan> savingsPlans;
  // Plans d'épargne mensuels

  Portfolio({
    required this.id,
    required this.name,
    List<Institution>? institutions,
    List<SavingsPlan>? savingsPlans,
  })  : institutions = institutions ?? [],
        savingsPlans = savingsPlans ?? [];

  double get totalValue {
    return institutions.fold(0.0, (sum, inst) => sum + inst.totalValue);
  }

  // NOUVEAU : Logique de P/L agrégée
  double get profitAndLoss {
    return institutions.fold(0.0, (sum, inst) => sum + inst.profitAndLoss);
  }

  // NOUVEAU : Capital investi total (somme de tous les achats)
  double get totalInvestedCapital {
    return institutions.fold(
        0.0, (sum, inst) => sum + inst.totalInvestedCapital);
  }

  // NOUVEAU : Logique de P/L en pourcentage
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
    final weightedYield = institutions.fold(0.0,
        (sum, inst) => sum + (inst.totalValue * inst.estimatedAnnualYield));
    return weightedYield / totalVal;
  }

  Portfolio deepCopy() {
    return Portfolio(
      id: id, // MIS À JOUR
      name: name, // MIS À JOUR
      institutions: institutions.map((inst) => inst.deepCopy()).toList(),
      savingsPlans: savingsPlans.map((plan) => plan.deepCopy()).toList(),
    );
  }

  // --- GETTER MODIFIÉ ---
  Map<AssetType, double> get valueByAssetType {
    final Map<AssetType, double> allocation = {};
    double totalCash = 0.0; // <-- NOUVEAU

    for (var inst in institutions) {
      for (var acc in inst.accounts) {
        // 1. Ajouter les liquidités du compte
        totalCash += acc.cashBalance; // <-- NOUVEAU

        // 2. Ajouter les actifs
        for (var asset in acc.assets) {
          allocation.update(
            asset.type,
            (value) => value + asset.totalValue,
            ifAbsent: () => asset.totalValue,
          );
        }
      }
    }

    // 3. Ajouter le total des liquidités à la map
    if (totalCash > 0) {
      allocation.update(
        AssetType.Cash,
        (value) => value + totalCash,
        ifAbsent: () => totalCash,
      );
    }
    // --- FIN MODIFICATION ---

    return allocation;
  }
}
