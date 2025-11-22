import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/features/00_app/services/crowdfunding_service.dart';

class CrowdfundingProjectionChart extends StatelessWidget {
  final List<Asset> assets;

  const CrowdfundingProjectionChart({
    super.key,
    required this.assets,
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

    // Limiter à 5 ans (60 mois) pour la lisibilité
    final displayProjections = projections; // On affiche tout, car on va scroller
    
    // Trouver le max pour l'échelle Y
    double maxY = 0;
    for (var p in displayProjections) {
      if (p.investedCapital > maxY) maxY = p.investedCapital;
      if (p.cumulativeInterest > maxY) maxY = p.cumulativeInterest;
    }
    maxY = maxY * 1.1; // Marge de 10%
    if (maxY == 0) maxY = 100;

    // Largeur dynamique : 50px par année (environ 4px par mois)
    // Minimum la largeur de l'écran
    final double chartWidth = (displayProjections.length * 10.0).clamp(MediaQuery.of(context).size.width - 64, 2000.0);

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
                maxX: displayProjections.length.toDouble() - 1,
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < displayProjections.length && index % 12 == 0) {
                          final date = displayProjections[index].date;
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
                    spots: displayProjections.asMap().entries.map((e) {
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
                    spots: displayProjections.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.cumulativeInterest);
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
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= displayProjections.length) return null;
                        final data = displayProjections[index];
                        final dateStr = DateFormat('MMM yyyy').format(data.date);
                        
                        String label = spot.barIndex == 0 ? "Capital" : "Intérêts";
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
              _buildLegendItem(Colors.blue, "Capital Restant"),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.green, "Intérêts Cumulés"),
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

  List<_MonthlyData> _calculateProjections() {
    final service = CrowdfundingService();
    final allProjections = service.generateProjections(assets);

    if (allProjections.isEmpty) return [];

    // Calculer le capital initial total (somme des investissements actuels)
    // Note: C'est une approximation. Idéalement on remonterait dans le temps.
    // Ici on part de "Maintenant" comme T0.
    
    double currentTotalCapital = 0;
    // On filtre d'abord pour ne garder que les actifs Crowdfunding
    final cfAssets = assets.where((a) => 
      a.repaymentType != null && 
      a.expectedYield != null && 
      a.quantity > 0
    ).toList();

    for (var asset in cfAssets) {
       // On ne compte que les assets qui ont généré des projections (donc valides)
       // Mais generateProjections filtre déjà.
       // On va sommer le capital de tous les assets crowdfunding actifs
       if (asset.quantity > 0 && asset.currentPrice > 0) { // Simplification
         currentTotalCapital += asset.quantity * asset.currentPrice;
       }
    }

    // Map date -> données agrégées
    final Map<DateTime, _MonthlyData> monthlyDataMap = {};
    
    // Date de début (aujourd'hui)
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    
    // Initialiser les mois futurs (ex: 5 ans)
    for (int i = 0; i < 60; i++) {
      final date = DateTime(startDate.year, startDate.month + i, 1);
      monthlyDataMap[date] = _MonthlyData(date: date, investedCapital: currentTotalCapital, cumulativeInterest: 0);
    }

    // Appliquer les flux futurs
    // Trier les projections par date
    allProjections.sort((a, b) => a.date.compareTo(b.date));

    double cumulativeInterest = 0;
    double repaidCapital = 0;

    // Pour chaque mois, on regarde ce qui s'est passé AVANT ou PENDANT ce mois
    // Mais attention, 'currentTotalCapital' est le capital AUJOURD'HUI.
    // Les projections sont FUTURES.
    // Donc quand un remboursement de capital arrive, le capital diminue.
    // Quand un intérêt arrive, le cumul augmente.

    for (var entry in monthlyDataMap.entries) {
      final monthDate = entry.key;
      final nextMonthDate = DateTime(monthDate.year, monthDate.month + 1, 1);

      // Trouver tous les flux qui ont lieu ce mois-ci
      final monthFlows = allProjections.where((p) => 
        (p.date.isAtSameMomentAs(monthDate) || p.date.isAfter(monthDate)) && 
        p.date.isBefore(nextMonthDate)
      );

      for (var flow in monthFlows) {
        if (flow.type == TransactionType.CapitalRepayment) {
          repaidCapital += flow.amount;
        } else if (flow.type == TransactionType.Interest) {
          cumulativeInterest += flow.amount;
        }
      }

      // Mettre à jour les données du mois
      // Le capital restant est le capital initial MOINS ce qui a été remboursé DEPUIS LE DÉBUT DE LA PROJECTION
      entry.value.investedCapital = currentTotalCapital - repaidCapital;
      entry.value.cumulativeInterest = cumulativeInterest;
    }

    return monthlyDataMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }
}

class _MonthlyData {
  final DateTime date;
  double investedCapital;
  double cumulativeInterest;

  _MonthlyData({
    required this.date,
    required this.investedCapital,
    required this.cumulativeInterest,
  });
}
