import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';

class CsvFilePicker extends StatelessWidget {
  final String? fileName;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  const CsvFilePicker({
    super.key,
    required this.fileName,
    required this.onPickFile,
    required this.onClearFile,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInSlide(
      delay: 0.2,
      child: AppCard(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          children: [
            if (fileName == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.table_chart_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    Text(
                      'Sélectionnez votre fichier CSV',
                      style: AppTypography.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      'Formats supportés : Revolut (CSV)',
                      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.paddingL),
                    AppButton(
                      label: 'Choisir un fichier',
                      onPressed: onPickFile,
                      icon: Icons.upload_file,
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    ),
                    child: const Icon(Icons.table_chart_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName!,
                          style: AppTypography.bodyBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Fichier prêt à être analysé',
                          style: AppTypography.label.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClearFile,
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
