import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/data/models/portfolio_value_history_point.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';

enum ChartTimeRange { day, month, year, max }

class PortfolioHistoryChart extends StatefulWidget {
  const PortfolioHistoryChart({super.key});

  @override
  State<PortfolioHistoryChart> createState() => _PortfolioHistoryChartState();
}

class _PortfolioHistoryChartState extends State<PortfolioHistoryChart> {
  ChartTimeRange _selectedRange = ChartTimeRange.max;

  @override
  Widget build(BuildContext context) {
    // Calcul responsive de la hauteur : 25% de l'écran, borné entre 200 et 350px
    final screenHeight = MediaQuery.of(context).size.height;
    final double chartHeight = (screenHeight * 0.25).clamp(200.0, 350.0);
    final currencyCode = context.select<SettingsProvider, String>((s) => s.baseCurrency);

    return Selector<PortfolioProvider, List<PortfolioValueHistoryPoint>>(
      selector: (context, provider) => provider.activePortfolio?.valueHistory ?? [],
      builder: (context, fullHistory, child) {
        
        // Filtrage des données selon la période sélectionnée
        final history = _filterHistory(fullHistory, _selectedRange);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // En-tête avec Titre et Filtres
            Padding(
              padding: AppSpacing.chartHeaderPaddingDefault,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Évolution',
                    style: AppTypography.h3,
                  ),
                  _buildTimeRangeSelector(),
                ],
              ),
            ),
            
            if (history.isEmpty)
              _buildPlaceholder("Pas de données pour cette période.", chartHeight)
            else if (history.length < 2 && _selectedRange != ChartTimeRange.day)
              _buildPlaceholder("Données insuffisantes pour le graphique.", chartHeight)
            else
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

  List<PortfolioValueHistoryPoint> _filterHistory(
      List<PortfolioValueHistoryPoint> fullHistory, ChartTimeRange range) {
    if (fullHistory.isEmpty) return [];
    if (range == ChartTimeRange.max) return List.from(fullHistory);

    final now = DateTime.now();
    DateTime cutoff;

    switch (range) {
      case ChartTimeRange.day:
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case ChartTimeRange.month:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case ChartTimeRange.year:
        cutoff = now.subtract(const Duration(days: 365));
        break;
      default:
        return fullHistory;
    }

    final filtered = fullHistory.where((p) => p.date.isAfter(cutoff)).toList();
    
    // Si on a moins de 2 points pour "Jour", on essaie d'ajouter le dernier point connu AVANT la période
    // pour avoir une ligne de continuité (sauf si aucun point avant).
    if (filtered.length < 2 && range != ChartTimeRange.max) {
       final pointsBefore = fullHistory.where((p) => p.date.isBefore(cutoff) || p.date.isAtSameMomentAs(cutoff)).toList();
       if (pointsBefore.isNotEmpty) {
         // On ajoute le dernier point d'avant comme point de départ "fictif" à la limite du cutoff
         // pour que le graphe ne soit pas vide.
         filtered.insert(0, pointsBefore.last);
       }
    }
    
    return filtered;
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRangeButton('1J', ChartTimeRange.day),
          _buildRangeButton('1M', ChartTimeRange.month),
          _buildRangeButton('1A', ChartTimeRange.year),
          _buildRangeButton('Max', ChartTimeRange.max),
        ],
      ),
    );
  }

  Widget _buildRangeButton(String label, ChartTimeRange range) {
    final isSelected = _selectedRange == range;
    return InkWell(
      onTap: () => setState(() => _selectedRange = range),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
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