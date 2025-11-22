import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/features/00_app/services/crowdfunding_service.dart';

class CrowdfundingProjectionChart extends StatelessWidget {
  final List<Asset> assets;
  final List<Transaction> transactions;

  const CrowdfundingProjectionChart({
    super.key,
    required this.assets,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final projections = _calculateProjections();

    if (projections.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Aucune donnée de projection disponible.")),
      );
    }

    // Trouver le max pour l'échelle Y
    double maxY = 0;
    for (var p in projections) {
      if (p.investedCapital > maxY) maxY = p.investedCapital;
      if (p.cumulativeInterests > maxY) maxY = p.cumulativeInterests;
      if (p.liquidity > maxY) maxY = p.liquidity;
    }
    maxY = maxY * 1.1; // Marge de 10%
    if (maxY == 0) maxY = 100;

    // Largeur dynamique : 30px par mois pour une meilleure lisibilité et scroll
    // Minimum la largeur de l'écran
    final double chartWidth = (projections.length * 30.0).clamp(MediaQuery.of(context).size.width - 64, 5000.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
          child: Text(
            "Projection Capital & Intérêts",
            style: AppTypography.h3,
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Container(
            height: 300,
            width: chartWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: projections.length.toDouble() - 1,
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < projections.length && index % 12 == 0) {
                          final date = projections[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('yyyy').format(date), style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          NumberFormat.compactCurrency(symbol: '').format(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Ligne Capital Investi
                  LineChartBarData(
                    spots: projections.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.investedCapital);
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                  // Ligne Intérêts Cumulés
                  LineChartBarData(
                    spots: projections.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.cumulativeInterests);
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.1),
                    ),
                  ),
                  // Ligne Liquidités Disponibles
                  LineChartBarData(
                    spots: projections.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.liquidity);
                    }).toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= projections.length) return null;
                        final data = projections[index];
                        final dateStr = DateFormat('MMM yyyy').format(data.date);
                        
                        String label;
                        if (spot.barIndex == 0) label = "Capital Investi";
                        else if (spot.barIndex == 1) label = "Intérêts Cumulés";
                        else label = "Liquidités Dispo";

                        return LineTooltipItem(
                          "$dateStr\n$label: ${NumberFormat.currency(symbol: '€').format(spot.y)}",
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.blue, "Capital Investi"),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.green, "Intérêts Cumulés"),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.orange, "Liquidités Dispo"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  List<CrowdfundingSimulationState> _calculateProjections() {
    final service = CrowdfundingService();
    final rawHistory = service.simulateCrowdfundingEvolution(
      assets: assets,
      transactions: transactions,
      projectionYears: 5,
    );
    
    if (rawHistory.isEmpty) return [];
    
    // Aggregate by month to avoid chart clutter
    final start = rawHistory.first.date;
    final end = rawHistory.last.date;
    final filledList = <CrowdfundingSimulationState>[];
    
    // Start from the first month
    var currentMonth = DateTime(start.year, start.month, 1);
    // Go up to the last month
    final endMonth = DateTime(end.year, end.month, 1);
    
    CrowdfundingSimulationState lastKnownState = rawHistory.first;
    
    while (!currentMonth.isAfter(endMonth)) {
      final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      
      // Find the last state that happened BEFORE the start of the next month
      final stateInMonth = rawHistory.lastWhere(
        (s) => s.date.isBefore(nextMonth),
        orElse: () => lastKnownState,
      );
      
      lastKnownState = stateInMonth;
      
      filledList.add(CrowdfundingSimulationState(
        date: currentMonth,
        liquidity: lastKnownState.liquidity,
        investedCapital: lastKnownState.investedCapital,
        cumulativeInterests: lastKnownState.cumulativeInterests,
        isProjected: lastKnownState.isProjected,
      ));
      
      currentMonth = nextMonth;
    }
    
    return filledList;
  }
}