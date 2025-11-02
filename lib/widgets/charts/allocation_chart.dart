import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/institution.dart';
import '../../models/portfolio.dart';

class AllocationChart extends StatefulWidget {
  final Portfolio portfolio;

  const AllocationChart({super.key, required this.portfolio});

  @override
  State<AllocationChart> createState() => _AllocationChartState();
}

class _AllocationChartState extends State<AllocationChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: _generateSections(
                    context,
                    widget.portfolio.institutions,
                    widget.portfolio.totalValue,
                  ),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(
      BuildContext context, List<Institution> institutions, double totalValue) {
    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      Colors.orange.shade400,
      Colors.teal.shade400,
      Colors.red.shade400,
    ];

    if (totalValue == 0) return [];

    return List.generate(institutions.length, (i) {
      final isTouched = i == touchedIndex;
      final institution = institutions[i];
      final percentage = (institution.totalValue / totalValue) * 100;
      final radius = isTouched ? 60.0 : 50.0;
      final fontSize = isTouched ? 16.0 : 14.0;

      return PieChartSectionData(
        color: colors[i % colors.length],
        value: percentage,
        title: isTouched
            ? institution.name
            : '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    });
  }
}
