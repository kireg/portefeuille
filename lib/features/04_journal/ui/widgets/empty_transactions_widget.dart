import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';

import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';

class EmptyTransactionsWidget extends StatelessWidget {
  final VoidCallback? onAdd;
  final VoidCallback? onImportPdf;
  final VoidCallback? onImportCrowdfunding;
  final VoidCallback? onImportAi;

  const EmptyTransactionsWidget({
    super.key,
    this.onAdd,
    this.onImportPdf,
    this.onImportCrowdfunding,
    this.onImportAi,
  });

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
              'Commencez par ajouter vos premières transactions.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            
            if (onAdd != null)
              AppButton(
                label: "Ajouter manuellement",
                icon: Icons.add,
                onPressed: onAdd,
              ),

            if (onImportPdf != null || onImportCrowdfunding != null || onImportAi != null) ...[
              const SizedBox(height: AppDimens.paddingM),
              Text("Ou importez en masse :", style: AppTypography.label),
              const SizedBox(height: AppDimens.paddingS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (onImportPdf != null)
                    AppButton(
                      label: "PDF",
                      icon: Icons.picture_as_pdf,
                      type: AppButtonType.secondary,
                      isFullWidth: false,
                      onPressed: onImportPdf,
                    ),
                  if (onImportCrowdfunding != null)
                    AppButton(
                      label: "Crowdfunding",
                      icon: Icons.table_view,
                      type: AppButtonType.secondary,
                      isFullWidth: false,
                      onPressed: onImportCrowdfunding,
                    ),
                  if (onImportAi != null)
                    AppButton(
                      label: "IA",
                      icon: Icons.auto_awesome,
                      type: AppButtonType.secondary,
                      isFullWidth: false,
                      onPressed: onImportAi,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
