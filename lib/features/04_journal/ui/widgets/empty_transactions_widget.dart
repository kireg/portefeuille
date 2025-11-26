import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';

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
            const SizedBox(width: 8),
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
              const SizedBox(height: 16),
              _buildHelpSection(
                "CSV Bancaires",
                "Importez vos exports CSV.",
                ["Revolut"],
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                "Crowdfunding",
                "Importez vos suivis de projets immobiliers.",
                ["La Première Brique (Excel)", "ClubFunding", "Raizers"],
              ),
              const SizedBox(height: 16),
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
        const SizedBox(height: 4),
        Text(description, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: examples.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
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
              size: 64,
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
                  height: 180,
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
              icon: const Icon(Icons.help_outline, size: 18),
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
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.h3.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
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
