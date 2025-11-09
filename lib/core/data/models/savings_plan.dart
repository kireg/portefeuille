import 'package:hive/hive.dart';

part 'savings_plan.g.dart';

/// Modèle représentant un plan d'épargne mensuel
/// Permet de simuler des investissements réguliers dans un actif existant du portefeuille
/// Le rendement est récupéré automatiquement depuis l'actif cible
@HiveType(typeId: 5)
class SavingsPlan {
  /// Identifiant unique du plan
  @HiveField(0)
  final String id;

  /// Nom du plan (ex: "Achat mensuel ETF World")
  @HiveField(1)
  String name;

  /// Montant investi chaque mois (en €)
  @HiveField(2)
  double monthlyAmount;

  /// Ticker de l'actif cible (référence à un actif du portefeuille)
  @HiveField(3)
  String targetTicker;

  /// Plan actif ou non
  @HiveField(4)
  bool isActive;

  SavingsPlan({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.targetTicker,
    this.isActive = true,
  });

  /// Calcule le capital total qui sera investi sur une période donnée
  /// [years] : durée en années
  double totalInvestedCapital(int years) {
    return monthlyAmount * 12 * years;
  }

  /// Calcule la valeur future avec intérêts composés
  /// Formule : VF = VM × [(1 + r/12)^n - 1] / (r/12) × (1 + r/12)
  /// où VM = versement mensuel, r = taux annuel, n = nombre de mois
  /// [years] : durée en années
  /// [estimatedAnnualReturn] : rendement annuel de l'actif cible
  double futureValue(int years, double estimatedAnnualReturn) {
    if (monthlyAmount <= 0 || years <= 0) return 0;
    
    final monthlyRate = estimatedAnnualReturn / 12;
    final months = years * 12;
    
    if (monthlyRate == 0) {
      // Cas sans rendement : juste la somme des versements
      return monthlyAmount * months;
    }
    
    // Formule de la valeur future d'une annuité
    final futureVal = monthlyAmount * 
      ((pow(1 + monthlyRate, months) - 1) / monthlyRate) * 
      (1 + monthlyRate);
    
    return futureVal;
  }

  /// Calcule le gain total (valeur future - capital investi)
  /// [years] : durée en années
  /// [estimatedAnnualReturn] : rendement annuel de l'actif cible
  double totalGain(int years, double estimatedAnnualReturn) {
    return futureValue(years, estimatedAnnualReturn) - totalInvestedCapital(years);
  }

  /// Crée une copie profonde du plan
  SavingsPlan deepCopy() {
    return SavingsPlan(
      id: id,
      name: name,
      monthlyAmount: monthlyAmount,
      targetTicker: targetTicker,
      isActive: isActive,
    );
  }
}

/// Fonction helper pour les calculs de puissance
/// Dart n'a pas de fonction pow native sans import
double pow(double base, int exponent) {
  if (exponent == 0) return 1;
  double result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
