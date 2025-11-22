import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';

class AssetTypeAllocationChart extends StatefulWidget {
  final Map<AssetType, double> allocationData;
  final double totalValue;

  const AssetTypeAllocationChart({
    super.key,
    required this.allocationData,
    required this.totalValue,
  });

  @override
  State<AssetTypeAllocationChart> createState() => _AssetTypeAllocationChartState();
}

class _AssetTypeAllocationChartState extends State<AssetTypeAllocationChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final bool hasData = widget.allocationData.isNotEmpty && widget.totalValue > 0;

    // MÊME LOGIQUE RESPONSIVE
    final screenHeight = MediaQuery.of(context).size.height;
    final double chartHeight = (screenHeight * 0.25).clamp(200.0, 350.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Répartition par actifs',
          style: AppTypography.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        if (hasData) ...[
          SizedBox(
            height: chartHeight,
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
                  widget.allocationData,
                  widget.totalValue,
                ),
                centerSpaceRadius: 60,
                sectionsSpace: 4,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingL),

          _buildLegend(widget.allocationData, widget.totalValue),
        ] else
          SizedBox(
            height: chartHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingL),
                child: Text(
                  'Aucune donnée',
                  style: AppTypography.caption,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<PieChartSectionData> _generateSections(
      Map<AssetType, double> allocationData,
      double totalValue,
      ) {
    if (totalValue <= 0) return [];

    final entries = allocationData.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final entry = entries[i];
      final percentage = (entry.value / totalValue) * 100;

      final radius = isTouched ? 30.0 : 20.0;
      final opacity = isTouched ? 1.0 : 0.8;

      if (entry.value <= 0) return PieChartSectionData(value: 0);

      return PieChartSectionData(
        color: AppColors.charts[i % AppColors.charts.length].withValues(alpha: opacity),
        value: entry.value,
        title: '',
        radius: radius,
        badgeWidget: isTouched ? _buildBadge(
            entry.key.displayName,
            percentage,
            AppColors.charts[i % AppColors.charts.length]
        ) : null,
        badgePositionPercentageOffset: 1.9,
      );
    }).where((section) => section.value > 0).toList();
  }

  Widget _buildBadge(String name, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: AppTypography.label.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<AssetType, double> allocationData, double totalValue) {
    final entries = allocationData.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: List.generate(entries.length, (i) {
        final entry = entries[i];
        if (entry.value <= 0) return const SizedBox.shrink();

        final percentage = (entry.value / totalValue) * 100;
        final color = AppColors.charts[i % AppColors.charts.length];
        final isTouched = i == touchedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isTouched ? AppColors.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key.displayName,
                  style: isTouched ? AppTypography.bodyBold : AppTypography.body,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        );
      }),
    );
  }
}