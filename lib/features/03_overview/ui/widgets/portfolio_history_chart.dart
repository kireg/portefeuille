import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/history_point.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

class PortfolioHistoryChart extends StatelessWidget {
  final List<HistoryPoint> history;
  final String currency;

  const PortfolioHistoryChart({
    super.key,
    required this.history,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text("Pas assez de données pour l'historique"));
    }

    // Sort just in case
    // history.sort((a, b) => a.date.compareTo(b.date)); // Assuming already sorted or list is mutable

    final spots = history.map((p) {
      return FlSpot(p.date.millisecondsSinceEpoch.toDouble(), p.value);
    }).toList();

    final minY = history.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxY = history.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final minX = spots.first.x;
    final maxX = spots.last.x;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.buildSectionHeader(
          context: context,
          icon: Icons.show_chart,
          title: 'Évolution du Portefeuille',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      // Show only start and end labels for simplicity, or calculate intervals
                      if (value == minX || value == maxX) {
                         return Padding(
                           padding: const EdgeInsets.only(top: 8.0),
                           child: Text(DateFormat('dd/MM/yy').format(date), style: const TextStyle(fontSize: 10)),
                         );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: minX,
              maxX: maxX,
              minY: minY * 0.95, // Add some padding
              maxY: maxY * 1.05,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                      final value = spot.y;
                      return LineTooltipItem(
                        '${DateFormat('dd/MM/yyyy').format(date)}\n${NumberFormat.currency(symbol: currency).format(value)}',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
