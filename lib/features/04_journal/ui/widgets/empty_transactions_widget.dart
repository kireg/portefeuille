import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_icon.dart';

class EmptyTransactionsWidget extends StatelessWidget {
  final VoidCallback? onImportHub;

  const EmptyTransactionsWidget({
    super.key,
    this.onImportHub,
  });

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: AppColors.primary),
            AppSpacing.gapHorizontalSmall,
            Text("Aide à l'import", style: AppTypography.h3),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                "PDF Bancaires",
                "Importez vos relevés de compte ou d'opérations.",
                ["Trade Republic", "Boursorama", "Fortuneo", "Degiro", "Interactive Brokers"],
              ),
              AppSpacing.gapM,
              _buildHelpSection(
                "CSV Bancaires",
                "Importez vos exports CSV.",
                ["Revolut"],
              ),
              AppSpacing.gapM,
              _buildHelpSection(
                "Crowdfunding",
                "Importez vos suivis de projets immobiliers.",
                ["La Première Brique (Excel)", "ClubFunding", "Raizers"],
              ),
              AppSpacing.gapM,
              _buildHelpSection(
                "IA (Expérimental)",
                "Copiez-collez n'importe quel texte ou CSV, l'IA tentera de le structurer.",
                ["Emails de confirmation", "Tableaux Excel divers", "Notes"],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Compris"),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String description, List<String> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.bodyBold),
        AppSpacing.gapXs,
        Text(description, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
        AppSpacing.gapS,
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: examples.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusXs2),
            ),
            child: Text(e, style: AppTypography.caption),
          )).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon(
              icon: Icons.receipt_long_outlined,
              size: AppComponentSizes.iconXxLarge,
              backgroundColor: AppColors.surfaceLight,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text('Aucune transaction', style: AppTypography.h2),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Commencez par alimenter votre journal.',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            
            // Single Action for Hub
            if (onImportHub != null)
              Center(
                child: SizedBox(
                  width: 300,
                  height: AppComponentSizes.importCardHeight,
                  child: _ActionCard(
                    title: "Ajouter / Importer",
                    subtitle: "Saisie manuelle ou Import de fichier",
                    icon: Icons.add_circle_outline,
                    color: AppColors.primary,
                    onTap: onImportHub!,
                  ),
                ),
              ),

            const SizedBox(height: AppDimens.paddingL),
            
            TextButton.icon(
              onPressed: () => _showHelpDialog(context),
              icon: const Icon(Icons.help_outline, size: AppComponentSizes.iconSmall),
              label: const Text("Quels fichiers sont supportés ?"),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: AppOpacities.lightOverlay),
              color.withValues(alpha: AppOpacities.subtle),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppComponentSizes.iconLarge, color: color),
            AppSpacing.gap12,
            Text(
              title,
              style: AppTypography.h3.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXs,
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
