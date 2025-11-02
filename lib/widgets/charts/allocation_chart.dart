import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/portfolio.dart';

class AllocationChart extends StatelessWidget {
  final Portfolio portfolio;

  const AllocationChart({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // TODO: Utiliser les vraies couleurs du thème
    final colors = [Colors.cyan[400], Colors.purple[400], Colors.orange[400], Colors.blue[400]];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Allocation par Établissement',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: _generateSections(),
                  pieTouchData: PieTouchData(touchCallback: (event, pieTouchResponse) {}),
                  centerSpaceRadius: 60,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

   List<PieChartSectionData> _generateSections() {
    // Exemple de données
    final data = {
      "Boursorama": 60.0,
      "Coinbase": 40.0,
    };

    return data.entries.map((entry) {
      return PieChartSectionData(
        color: Colors.cyan, // A améliorer
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

}
