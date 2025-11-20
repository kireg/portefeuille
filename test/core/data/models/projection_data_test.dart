import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/projection_data.dart';

void main() {
  group('ProjectionCalculator', () {
    test('generateProjectionData calculates correctly for 3 years', () {
      // Hypothèses de l'issue :
      // Capital actuel initial : 32 909,70 €
      // Plans d'épargne : 400 €/mois (4 800 €/an)
      // Rendement moyen pondéré : ~7.2%
      
      // Note: The calculator uses portfolioAnnualYield for the base capital
      // and averagePlansYield for the monthly contributions.
      // In the issue example, it seems they might be using the same yield or similar.
      // Let's use 7.2% for both for simplicity to match the example logic roughly,
      // or just verify the structure.

      final double initialCapital = 32909.70;
      final double monthlyInvestment = 400.0;
      final double yield = 0.072; // 7.2%

      final data = ProjectionCalculator.generateProjectionData(
        duration: 3,
        initialPortfolioValue: initialCapital,
        initialInvestedCapital: initialCapital, // Not used in new logic but required
        portfolioAnnualYield: yield,
        totalMonthlyInvestment: monthlyInvestment,
        averagePlansYield: yield,
      );

      expect(data.length, 3);

      // Year 1
      // Capital actuel should be constant
      expect(data[0].currentCapital, initialCapital);
      // Cumulative contributions: 400 * 12 * 1 = 4800
      expect(data[0].cumulativeContributions, 4800.0);
      // Total value should be > capital + contributions (due to gains)
      expect(data[0].totalValue, greaterThan(initialCapital + 4800.0));
      // Cumulative gains = Total - Capital - Contributions
      expect(data[0].cumulativeGains, closeTo(data[0].totalValue - initialCapital - 4800.0, 0.01));

      // Year 2
      expect(data[1].currentCapital, initialCapital);
      expect(data[1].cumulativeContributions, 9600.0); // 4800 * 2
      expect(data[1].totalValue, greaterThan(data[0].totalValue));

      // Year 3
      expect(data[2].currentCapital, initialCapital);
      expect(data[2].cumulativeContributions, 14400.0); // 4800 * 3
    });

    test('generateProjectionData with 0 yield', () {
      final double initialCapital = 10000.0;
      final double monthlyInvestment = 100.0;
      final double yield = 0.0;

      final data = ProjectionCalculator.generateProjectionData(
        duration: 5,
        initialPortfolioValue: initialCapital,
        initialInvestedCapital: initialCapital,
        portfolioAnnualYield: yield,
        totalMonthlyInvestment: monthlyInvestment,
        averagePlansYield: yield,
      );

      // Year 1
      expect(data[0].currentCapital, initialCapital);
      expect(data[0].cumulativeContributions, 1200.0);
      expect(data[0].cumulativeGains, 0.0);
      expect(data[0].totalValue, initialCapital + 1200.0);

      // Year 5
      expect(data[4].currentCapital, initialCapital);
      expect(data[4].cumulativeContributions, 1200.0 * 5);
      expect(data[4].cumulativeGains, 0.0);
      expect(data[4].totalValue, initialCapital + (1200.0 * 5));
    });
  });
}
