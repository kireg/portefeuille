import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';

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
    final bool hasData = widget.portfolio.institutions.isNotEmpty && widget.portfolio.totalValue > 0;

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
              child: hasData
                  ? PieChart(
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
                    )
                  : Center(
                      child: Text(
                        'Aucune donnée d\'allocation disponible.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
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

    // Return an empty list if there is no value, to prevent division by zero
    if (totalValue <= 0) return [];

    return List.generate(institutions.length, (i) {
      final isTouched = i == touchedIndex;
      final institution = institutions[i];
      final percentage = (institution.totalValue / totalValue) * 100;
      final radius = isTouched ? 60.0 : 50.0;
      final fontSize = isTouched ? 16.0 : 14.0;

      // Avoid creating a section with no value
      if (institution.totalValue <= 0) {
        return PieChartSectionData(value: 0); // Return a dummy, invisible section
      }

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
    }).where((section) => section.value > 0).toList(); // Filter out dummy sections
  }
}
