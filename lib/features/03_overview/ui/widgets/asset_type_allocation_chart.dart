// lib/features/03_overview/ui/widgets/asset_type_allocation_chart.dart
// NOUVEAU FICHIER

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

class AssetTypeAllocationChart extends StatefulWidget {
  final Map<AssetType, double> allocationData;
  final double totalValue;

  const AssetTypeAllocationChart({
    super.key,
    required this.allocationData,
    required this.totalValue,
  });

  @override
  State<AssetTypeAllocationChart> createState() =>
      _AssetTypeAllocationChartState();
}

class _AssetTypeAllocationChartState extends State<AssetTypeAllocationChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasData =
        widget.allocationData.isNotEmpty && widget.totalValue > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allocation par Type d\'Actif',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: hasData
                  ? PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: _generateSections(
                          context,
                          widget.allocationData,
                          widget.totalValue,
                        ),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    )
                  : Center(
                      child: Text(
                        'Aucune donnée d\'allocation disponible.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(
    BuildContext context,
    Map<AssetType, double> allocationData,
    double totalValue,
  ) {
    // Palette de couleurs statique
    final List<Color> colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.red.shade400,
      Colors.amber.shade600,
    ];

    if (totalValue <= 0) return [];

    // Convertir la Map en Liste pour l'indexation
    final entries = allocationData.entries.toList();

    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final entry = entries[i];
      final assetType = entry.key;
      final value = entry.value;

      // CORRIGÉ : Le pourcentage est calculé ici (0-100),
      // ne pas multiplier par 100 une seconde fois
      final percentage = (value / totalValue) * 100;
      final radius = isTouched ? 60.0 : 50.0;
      final fontSize = isTouched ? 16.0 : 14.0;

      if (value <= 0) {
        return PieChartSectionData(value: 0); // Section invisible
      }

      return PieChartSectionData(
        color: colors[i % colors.length],
        value: value, // CORRIGÉ : Utiliser la valeur brute, pas le pourcentage
        title: isTouched
            ? assetType.displayName // Utilise l'extension
            : '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    }).where((section) => section.value > 0).toList();
  }
}
