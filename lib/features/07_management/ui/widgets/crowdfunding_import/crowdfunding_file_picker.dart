import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';

class CrowdfundingFilePicker extends StatelessWidget {
  final String? fileName;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  const CrowdfundingFilePicker({
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
                        Icons.table_view_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    Text(
                      "Importez votre fichier Excel",
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: AppDimens.paddingXS),
                    Text(
                      "Formats supportés : .xlsx, .xls",
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingL),
                    AppButton(
                      label: "Sélectionner le fichier",
                      icon: Icons.folder_open,
                      onPressed: onPickFile,
                    ),
                  ],
                ),
              )
            else
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: AppColors.primary),
                title: Text(fileName!, style: AppTypography.bodyBold),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClearFile,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
