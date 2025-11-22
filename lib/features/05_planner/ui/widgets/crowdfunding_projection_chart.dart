import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/features/00_app/services/crowdfunding_service.dart';

class CrowdfundingProjectionChart extends StatefulWidget {
  final List<Asset> assets;
  final List<Transaction> transactions;

  const CrowdfundingProjectionChart({
    super.key,
    required this.assets,
    required this.transactions,
  });

  @override
  State<CrowdfundingProjectionChart> createState() => _CrowdfundingProjectionChartState();
}

class _CrowdfundingProjectionChartState extends State<CrowdfundingProjectionChart> {
  int _projectionYears = 5;
  CrowdfundingSimulationState? _selectedState;

  @override
  Widget build(BuildContext context) {
    final projections = _calculateProjections();

    if (projections.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Aucune donnée de projection disponible.")),
      );
    }

    // Par défaut, afficher le dernier état si aucun n'est sélectionné
    final displayState = _selectedState ?? projections.last;

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Projection",
                style: AppTypography.h3,
              ),
              _buildTimeRangeSelector(),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        
        // Résumé dynamique
        _buildDynamicSummary(displayState),
        
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
                clipData: const FlClipData.all(),
                minX: 0,
                maxX: projections.length.toDouble() - 1,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
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
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.3),
                          Colors.blue.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha: 0.3),
                          Colors.green.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.3),
                          Colors.orange.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (event is FlTapUpEvent || event is FlPanEndEvent) {
                       // Reset selection on end? No, keep it.
                    }
                    
                    if (touchResponse != null && touchResponse.lineBarSpots != null && touchResponse.lineBarSpots!.isNotEmpty) {
                      final index = touchResponse.lineBarSpots!.first.x.toInt();
                      if (index >= 0 && index < projections.length) {
                        setState(() {
                          _selectedState = projections[index];
                        });
                      }
                    }
                  },
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        // Tooltip minimaliste car on a le résumé en haut
                        return null; 
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
              _buildLegendItem(Colors.blue, "Capital"),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.green, "Intérêts"),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.orange, "Liquidités"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicSummary(CrowdfundingSimulationState state) {
    final currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 0);
    final dateFormat = DateFormat('MMM yyyy', 'fr_FR');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              dateFormat.format(state.date).toUpperCase(),
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryValue("Capital", state.investedCapital, Colors.blue, currencyFormat),
                _buildSummaryValue("Intérêts", state.cumulativeInterests, Colors.green, currencyFormat),
                _buildSummaryValue("Liquidités", state.liquidity, Colors.orange, currencyFormat),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryValue(String label, double value, Color color, NumberFormat fmt) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        Text(
          fmt.format(value),
          style: AppTypography.bodyBold.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [1, 3, 5, 10].map((years) {
        final isSelected = _projectionYears == years;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: InkWell(
            onTap: () => setState(() {
              _projectionYears = years;
              _selectedState = null; // Reset selection on range change
            }),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                "${years}A",
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
      assets: widget.assets,
      transactions: widget.transactions,
      projectionYears: _projectionYears,
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