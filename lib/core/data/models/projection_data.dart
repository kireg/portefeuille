import 'dart:math';

class ProjectionData {
  final int year;
  final double currentCapital;
  final double cumulativeContributions;
  final double cumulativeGains;
  final double totalValue;

  ProjectionData({
    required this.year,
    required this.currentCapital,
    required this.cumulativeContributions,
    required this.cumulativeGains,
    required this.totalValue,
  });
}

class ProjectionCalculator {
  // Fonction statique pour générer les données de projection
  static List<ProjectionData> generateProjectionData({
    required int duration,
    required double initialPortfolioValue,
    required double initialInvestedCapital, // Not used anymore for projection logic as per new requirements, but kept if needed or we can remove it. The issue says "Capital actuel" should be the current portfolio value.
    required double portfolioAnnualYield,
    required double totalMonthlyInvestment,
    required double averagePlansYield,
  }) {
    List<ProjectionData> data = [];

    for (int year = 1; year <= duration; year++) {
      // 1. Future value of current capital (Compound interest)
      final double futureBaseValue =
          initialPortfolioValue * pow(1 + portfolioAnnualYield, year);

      // 2. Future value of monthly contributions (Compound interest)
      final double futureSavingsValue = (totalMonthlyInvestment > 0 && averagePlansYield > 0)
          ? totalMonthlyInvestment * 12 * ((pow(1 + averagePlansYield, year) - 1) / averagePlansYield) * (1 + averagePlansYield / 12)
          : totalMonthlyInvestment * 12 * year;

      // 3. Total projected value
      final double totalValue = futureBaseValue + futureSavingsValue;

      // 4. Components
      final double currentCapital = initialPortfolioValue;
      final double cumulativeContributions = totalMonthlyInvestment * 12 * year;
      final double cumulativeGains = totalValue - currentCapital - cumulativeContributions;

      data.add(ProjectionData(
        year: year,
        currentCapital: currentCapital,
        cumulativeContributions: cumulativeContributions,
        cumulativeGains: cumulativeGains,
        totalValue: totalValue,
      ));
    }
    return data;
  }
}