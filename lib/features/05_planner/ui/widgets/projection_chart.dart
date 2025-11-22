import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:portefeuille/core/data/models/projection_data.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';

class ProjectionChart extends StatelessWidget {
  final List<ProjectionData> data;
  final String baseCurrency;
  final bool isLoading;
  final int duration;

  const ProjectionChart({
    super.key,
    required this.data,
    required this.baseCurrency,
    required this.isLoading,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BarChart(_buildChartData()),
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ],
    );
  }

  BarChartData _buildChartData() {
    final lastData = data.last;
    final maxValue = lastData.totalValue;

    return BarChartData(
      maxY: maxValue * 1.1,
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          // --- CORRECTION ICI ---
          // On utilise uniquement la couleur de fond disponible
          getTooltipColor: (group) => AppColors.surfaceLight,

          // On supprime getTooltipBorder et tooltipRoundedRadius qui causaient l'erreur
          // Le radius par défaut est généralement de 4.0, ce qui correspond au style badge

          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tooltipMargin: 8,
          fitInsideHorizontally: true,
          fitInsideVertically: true,

          // --- CONTENU DU TOOLTIP ---
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final d = data[groupIndex];
            final investedAmount = d.currentCapital + d.cumulativeContributions;

            return BarTooltipItem(
              'Année ${d.year}\n',
              AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              children: [
                // Espaceur visuel
                const TextSpan(text: '\n', style: TextStyle(fontSize: 4)),

                // Ligne 1 : Montant Investi
                TextSpan(
                  text: 'Investi: ',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                TextSpan(
                  text: '${CurrencyFormatter.format(investedAmount, baseCurrency)}\n',
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),

                // Ligne 2 : Gains
                TextSpan(
                  text: 'Gains: ',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                TextSpan(
                  text: '+${CurrencyFormatter.format(d.cumulativeGains, baseCurrency)}\n',
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.success,
                    fontSize: 11,
                  ),
                ),

                // Ligne 3 : Total
                TextSpan(
                  text: 'Total: ',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                TextSpan(
                  text: CurrencyFormatter.format(d.totalValue, baseCurrency),
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final year = value.toInt();
              final int step = duration > 10 ? 5 : 2;
              if (year % step != 0 && year != 1 && year != duration) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('$year', style: AppTypography.caption),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox();
              return Text(
                NumberFormat.compact().format(value),
                style: AppTypography.caption.copyWith(fontSize: 10),
                textAlign: TextAlign.right,
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barGroups: data.map((d) {
        return BarChartGroupData(
          x: d.year,
          barRods: [
            BarChartRodData(
              toY: d.totalValue,
              width: duration > 20 ? 8 : 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              rodStackItems: [
                BarChartRodStackItem(
                    0,
                    d.currentCapital,
                    AppColors.primary.withValues(alpha: 0.5)
                ),
                BarChartRodStackItem(
                    d.currentCapital,
                    d.currentCapital + d.cumulativeContributions,
                    AppColors.accent.withValues(alpha: 0.5)
                ),
                BarChartRodStackItem(
                    d.currentCapital + d.cumulativeContributions,
                    d.totalValue,
                    AppColors.success
                ),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }
}