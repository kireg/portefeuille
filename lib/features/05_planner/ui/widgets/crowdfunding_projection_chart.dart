import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'package:portefeuille/features/00_app/services/crowdfunding_service.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';

class CrowdfundingProjectionChart extends StatefulWidget {
  final List<Asset> assets;
  final List<Transaction> transactions;
  final List<Account> accounts;

  const CrowdfundingProjectionChart({
    super.key,
    required this.assets,
    required this.transactions,
    this.accounts = const [],
  });

  @override
  State<CrowdfundingProjectionChart> createState() => _CrowdfundingProjectionChartState();
}

class _CrowdfundingProjectionChartState extends State<CrowdfundingProjectionChart> {
  int _projectionMonths = 60; // Default 5 years
  CrowdfundingSimulationState? _selectedState;
  late Future<List<CrowdfundingSimulationState>> _projectionsFuture;

  @override
  void initState() {
    super.initState();
    _projectionsFuture = _calculateProjectionsAsync();
  }

  @override
  void didUpdateWidget(CrowdfundingProjectionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.assets != oldWidget.assets || 
        widget.transactions != oldWidget.transactions || 
        widget.accounts != oldWidget.accounts) {
      _projectionsFuture = _calculateProjectionsAsync();
    }
  }

  Future<List<CrowdfundingSimulationState>> _calculateProjectionsAsync() async {
    // Allow UI to render first
    await Future.delayed(Duration.zero);
    return _calculateProjections();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CrowdfundingSimulationState>>(
      future: _projectionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const SizedBox(
             height: 300,
             child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
           );
        }
        
        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text("Erreur de calcul: ${snapshot.error}")),
          );
        }

        final projections = snapshot.data ?? [];

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
          final total = p.investedCapital + p.cumulativeInterests; // Exclure liquidités
          if (total > maxY) maxY = total;
        }
        maxY = maxY * 1.1; // Marge de 10%
        if (maxY == 0) maxY = 100;

        // Largeur dynamique : 16px par mois pour les barres + padding
        final double chartWidth = (projections.length * 16.0 + 32.0).clamp(MediaQuery.of(context).size.width - 64, 5000.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Column(
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
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    // Ensure we show all groups
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => AppColors.surfaceLight,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        tooltipMargin: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final state = projections[groupIndex];
                          final total = state.investedCapital + state.cumulativeInterests + state.liquidity;
                          final currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 0);

                          return BarTooltipItem(
                            '${DateFormat('MMM yyyy', 'fr_FR').format(state.date)}\n',
                            AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              const TextSpan(text: '\n', style: TextStyle(fontSize: 4)),
                              _buildTooltipSpan("Liquidités: ", state.liquidity, AppColors.warning, currencyFormat),
                              _buildTooltipSpan("Capital: ", state.investedCapital, AppColors.primary, currencyFormat),
                              _buildTooltipSpan("Intérêts: ", state.cumulativeInterests, AppColors.success, currencyFormat),
                              const TextSpan(text: '\n'),
                              TextSpan(
                                text: 'Total: ',
                                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                              ),
                              TextSpan(
                                text: currencyFormat.format(total),
                                style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary, fontSize: 12),
                              ),
                            ],
                          );
                        },
                      ),
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (!event.isInterestedForInteractions ||
                            barTouchResponse == null ||
                            barTouchResponse.spot == null) {
                          return;
                        }
                        final index = barTouchResponse.spot!.touchedBarGroupIndex;
                        if (index >= 0 && index < projections.length) {
                          setState(() {
                            _selectedState = projections[index];
                          });
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < projections.length && index % 12 == 0) {
                              final date = projections[index].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(DateFormat('yyyy').format(date), style: AppTypography.caption),
                              );
                            }
                            return const SizedBox.shrink();
                          },
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
                              style: AppTypography.caption.copyWith(fontSize: 10),
                              textAlign: TextAlign.right,
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: projections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final total = data.investedCapital + data.cumulativeInterests;
                      
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: total,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            rodStackItems: [
                              // Order: Capital (Bottom), Interest (Top)
                              BarChartRodStackItem(0, data.investedCapital, AppColors.primary),
                              BarChartRodStackItem(data.investedCapital, total, AppColors.success),
                            ],
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            AppSpacing.gapS,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(AppColors.primary, "Capital"),
                  AppSpacing.gapHorizontalMedium,
                  _buildLegendItem(AppColors.success, "Intérêts"),
                ],
              ),
            ),
          ],
        ),
      );
      },
    );
  }

  TextSpan _buildTooltipSpan(String label, double value, Color color, NumberFormat fmt) {
    return TextSpan(
      children: [
        TextSpan(
          text: label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
        ),
        TextSpan(
          text: '${fmt.format(value)}\n',
          style: AppTypography.bodyBold.copyWith(color: color, fontSize: 11),
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
          borderRadius: BorderRadius.circular(AppDimens.radius12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              dateFormat.format(state.date).toUpperCase(),
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.gapS,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryValue("Liquidités", state.liquidity, AppColors.warning, currencyFormat),
                _buildSummaryValue("Capital", state.investedCapital, AppColors.primary, currencyFormat),
                _buildSummaryValue("Intérêts", state.cumulativeInterests, AppColors.success, currencyFormat),
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
    final options = [6, 12, 24, 60, 120];
    final labels = ["6M", "1A", "2A", "5A", "10A"];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (index) {
        final months = options[index];
        final label = labels[index];
        final isSelected = _projectionMonths == months;
        
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: InkWell(
            onTap: () => setState(() {
              _projectionMonths = months;
              _selectedState = null; // Reset selection on range change
              _projectionsFuture = _calculateProjectionsAsync();
            }),
            borderRadius: BorderRadius.circular(AppDimens.radius12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimens.radius12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: AppOpacities.decorative),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
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
        AppSpacing.gapH4,
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  List<CrowdfundingSimulationState> _calculateProjections() {
    final service = CrowdfundingService();
    final rawHistory = service.simulateCrowdfundingEvolution(
      assets: widget.assets,
      transactions: widget.transactions,
      accounts: widget.accounts,
      projectionMonths: _projectionMonths,
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