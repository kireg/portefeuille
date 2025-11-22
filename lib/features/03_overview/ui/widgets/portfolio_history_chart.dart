import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/core/data/models/portfolio_value_history_point.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';

class PortfolioHistoryChart extends StatefulWidget {
  const PortfolioHistoryChart({super.key});

  @override
  State<PortfolioHistoryChart> createState() => _PortfolioHistoryChartState();
}

class _PortfolioHistoryChartState extends State<PortfolioHistoryChart> {
  @override
  Widget build(BuildContext context) {
    // Calcul responsive de la hauteur : 25% de l'écran, borné entre 200 et 350px
    final screenHeight = MediaQuery.of(context).size.height;
    final double chartHeight = (screenHeight * 0.25).clamp(200.0, 350.0);

    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final history = provider.activePortfolio?.valueHistory ?? [];
        final currencyCode = provider.currentBaseCurrency;

        if (history.isEmpty) {
          return _buildPlaceholder("Pas encore d'historique.", chartHeight);
        }
        if (history.length < 2) {
          return _buildPlaceholder("Données insuffisantes pour le graphique.", chartHeight);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                'Évolution',
                style: AppTypography.h3,
              ),
            ),
            // Remplacement de AspectRatio par SizedBox avec hauteur dynamique uniforme
            SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 24, 10),
                child: LineChart(
                  _mainData(history, currencyCode),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder(String message, double height) {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: Text(
        message,
        style: AppTypography.caption,
        textAlign: TextAlign.center,
      ),
    );
  }

  LineChartData _mainData(
      List<PortfolioValueHistoryPoint> history,
      String currencyCode
      ) {
    // Tri
    history.sort((a, b) => a.date.compareTo(b.date));

    final spots = history.map((point) {
      return FlSpot(
        point.date.millisecondsSinceEpoch.toDouble(),
        point.value,
      );
    }).toList();

    // Min/Max
    double minY = history.map((e) => e.value).reduce((curr, next) => curr < next ? curr : next);
    double maxY = history.map((e) => e.value).reduce((curr, next) => curr > next ? curr : next);

    // Marge esthétique (10% haut/bas)
    final double margin = (maxY - minY) * 0.1;
    minY = (margin == 0) ? minY * 0.9 : minY - margin;
    maxY = (margin == 0) ? maxY * 1.1 : maxY + margin;

    final primaryColor = Theme.of(context).colorScheme.primary;

    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateDateInterval(history),
            getTitlesWidget: (value, meta) {
              if (value == spots.last.x) return const SizedBox.shrink();
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('dd/MM').format(date),
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            interval: (maxY - minY) / 3,
            getTitlesWidget: (value, meta) {
              if (value == minY || value == maxY) return const SizedBox.shrink();
              return Text(
                NumberFormat.compact().format(value),
                style: AppTypography.caption.copyWith(fontSize: 10),
                textAlign: TextAlign.right,
              );
            },
          ),
        ),
      ),
      minX: spots.first.x,
      maxX: spots.last.x,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          shadow: Shadow(
            color: AppColors.primary.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.3),
                AppColors.primary.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppColors.surfaceLight,
          tooltipPadding: const EdgeInsets.all(12),
          tooltipBorder: BorderSide(color: AppColors.border),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
              final formattedValue = CurrencyFormatter.format(touchedSpot.y, currencyCode);
              return LineTooltipItem(
                '${DateFormat('dd MMM', 'fr_FR').format(date)}\n',
                AppTypography.caption,
                children: [
                  TextSpan(
                    text: formattedValue,
                    style: AppTypography.bodyBold.copyWith(color: primaryColor),
                  ),
                ],
              );
            }).toList();
          },
        ),
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              FlLine(color: primaryColor, strokeWidth: 2, dashArray: [4, 4]),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: AppColors.background,
                    strokeWidth: 3,
                    strokeColor: AppColors.primary,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
    );
  }

  double _calculateDateInterval(List<PortfolioValueHistoryPoint> history) {
    if (history.isEmpty) return 1.0;
    final diff = history.last.date.difference(history.first.date).inMilliseconds;
    if (diff == 0) return 1.0;
    return diff / 4;
  }
}