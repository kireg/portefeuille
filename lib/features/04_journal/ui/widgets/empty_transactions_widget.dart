import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';

class EmptyTransactionsWidget extends StatelessWidget {
  const EmptyTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: AppCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon(
              icon: Icons.receipt_long_outlined,
              size: 48,
              backgroundColor: AppColors.surfaceLight,
            ),
            const SizedBox(height: AppDimens.paddingM),
            Text('Aucune transaction', style: AppTypography.h3),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Utilisez le bouton "+" pour commencer.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
