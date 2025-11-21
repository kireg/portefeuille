// lib/features/04_summary/ui/widgets/summary_empty_state.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';

class SummaryEmptyState extends StatelessWidget {
  final double topPadding;

  const SummaryEmptyState({
    super.key,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: AppDimens.paddingL),
          child: Text('Synthèse', style: AppTypography.h2),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: AppCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    icon: Icons.pie_chart_outline,
                    size: 48,
                    backgroundColor: AppColors.surfaceLight,
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  Text('Aucun actif', style: AppTypography.h3),
                  const SizedBox(height: AppDimens.paddingS),
                  Text(
                    'Ajoutez des transactions pour voir vos actifs ici.',
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}