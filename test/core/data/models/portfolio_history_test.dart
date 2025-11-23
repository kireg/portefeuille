import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/portfolio_value_history_point.dart';

void main() {
  group('Portfolio History Logic', () {
    test('addOrUpdateHistoryPoint adds a new point if history is empty', () {
      final portfolio = Portfolio(id: '1', name: 'Test');
      final changed = portfolio.addOrUpdateHistoryPoint(100.0);

      expect(changed, true);
      expect(portfolio.valueHistory.length, 1);
      expect(portfolio.valueHistory.first.value, 100.0);
    });

    test('addOrUpdateHistoryPoint updates existing point if same day', () {
      final portfolio = Portfolio(id: '1', name: 'Test');
      
      // Add first point
      portfolio.addOrUpdateHistoryPoint(100.0);
      
      // Update same day with different value
      final changed = portfolio.addOrUpdateHistoryPoint(200.0);

      expect(changed, true);
      expect(portfolio.valueHistory.length, 1);
      expect(portfolio.valueHistory.first.value, 200.0);
    });

    test('addOrUpdateHistoryPoint does not update if value is similar', () {
      final portfolio = Portfolio(id: '1', name: 'Test');
      
      // Add first point
      portfolio.addOrUpdateHistoryPoint(100.0);
      
      // Update same day with similar value
      final changed = portfolio.addOrUpdateHistoryPoint(100.005);

      expect(changed, false);
      expect(portfolio.valueHistory.length, 1);
      expect(portfolio.valueHistory.first.value, 100.0);
    });

    test('addOrUpdateHistoryPoint adds new point for different day', () {
      final portfolio = Portfolio(id: '1', name: 'Test');
      
      // Mock history with a past date
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      portfolio.valueHistory.add(PortfolioValueHistoryPoint(date: yesterday, value: 50.0));

      // Add today's point
      final changed = portfolio.addOrUpdateHistoryPoint(100.0);

      expect(changed, true);
      expect(portfolio.valueHistory.length, 2);
      expect(portfolio.valueHistory.last.value, 100.0);
    });
    test('addOrUpdateHistoryPoint ignores 0 value if history has data', () {
      final portfolio = Portfolio(id: '1', name: 'Test');
      
      // Add valid point
      portfolio.addOrUpdateHistoryPoint(100.0);
      
      // Try to add 0 (simulating error)
      final changed = portfolio.addOrUpdateHistoryPoint(0.0);

      expect(changed, false);
      expect(portfolio.valueHistory.length, 1);
      expect(portfolio.valueHistory.first.value, 100.0);
    });

    test('addOrUpdateHistoryPoint accepts 0 value if history is empty', () {
      final portfolio = Portfolio(id: '1', name: 'Test');
      
      // Add 0 as first point
      final changed = portfolio.addOrUpdateHistoryPoint(0.0);

      expect(changed, true);
      expect(portfolio.valueHistory.length, 1);
      expect(portfolio.valueHistory.first.value, 0.0);
    });
  });
}
