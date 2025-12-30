import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/features/09_imports/ui/screens/file_import_wizard.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_transaction_screen.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';

class ImportHubScreen extends StatelessWidget {
  const ImportHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: AppOpacities.decorative),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                ),
              ),
            ),
            AppSpacing.gapL,
            
            Text(
              'Ajouter une transaction',
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapS,
            Text(
              'Comment souhaitez-vous ajouter vos données ?',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXl,
            
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    context,
                    title: 'Saisie\nManuelle',
                    description: 'Rapide & Unitaire',
                    icon: Icons.edit_note,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => const AddTransactionScreen(),
                      );
                    },
                  ),
                ),
                AppSpacing.gapHorizontalMedium,
                Expanded(
                  child: _buildOptionCard(
                    context,
                    title: 'Importer\nun Fichier',
                    description: 'PDF, CSV, Excel...',
                    icon: Icons.upload_file,
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.pop(context); // Close Hub
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const FileImportWizard(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(
          color: color.withValues(alpha: AppOpacities.semiVisible),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: AppOpacities.lightOverlay),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: AppOpacities.lightOverlay),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: AppOpacities.border)),
                      ),
                      child: Icon(icon, size: AppComponentSizes.iconLarge, color: color),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: AppTypography.h3.copyWith(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapXs,
                    Text(
                      description,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
