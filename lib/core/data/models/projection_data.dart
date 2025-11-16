import 'dart:math';

class ProjectionData {
  final int year;
  final double initialInvestedCapital;
  final double currentPortfolioValue;
  final double newInvestments;
  final double totalValue;

  ProjectionData({
    required this.year,
    required this.initialInvestedCapital,
    required this.currentPortfolioValue,
    required this.newInvestments,
    required this.totalValue,
  });

  double get investedCapital => initialInvestedCapital + newInvestments;
  double get totalGain => totalValue - investedCapital;
  double get realizedGains => currentPortfolioValue - initialInvestedCapital;
  double get projectedGains => totalValue - currentPortfolioValue - newInvestments;
}

class ProjectionCalculator {
  // Fonction statique pour générer les données de projection
  static List<ProjectionData> generateProjectionData({
    required int duration,
    required double initialPortfolioValue,
    required double initialInvestedCapital,
    required double portfolioAnnualYield,
    required double totalMonthlyInvestment,
    required double averagePlansYield,
  }) {
    List<ProjectionData> data = [];

    for (int year = 1; year <= duration; year++) {
      final double futureBaseValue =
          initialPortfolioValue * pow(1 + portfolioAnnualYield, year);

      // Calcul de la valeur future des versements
      final double futureSavingsValue = (totalMonthlyInvestment > 0 && averagePlansYield > 0)
          ? totalMonthlyInvestment * 12 * ((pow(1 + averagePlansYield, year) - 1) / averagePlansYield) * (1 + averagePlansYield / 12) // Approximation pour versements mensuels
          : totalMonthlyInvestment * 12 * year; // Cas sans intérêt composé

      final double newInvestments = totalMonthlyInvestment * 12 * year;
      final double totalValue = futureBaseValue + futureSavingsValue;

      data.add(ProjectionData(
        year: year,
        initialInvestedCapital: initialInvestedCapital,
        currentPortfolioValue: initialPortfolioValue,
        newInvestments: newInvestments,
        totalValue: totalValue,
      ));
    }
    return data;
  }
}