// lib/features/06_settings/ui/widgets/danger_zone_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/01_launch/ui/launch_screen.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';

class DangerZoneCard extends StatelessWidget {
  const DangerZoneCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer.withValues(alpha: AppOpacities.lightOverlay),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: AppOpacities.decorative)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Centré
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centré
              children: [
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                AppSpacing.gapH12,
                Text('Zone de danger',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.error,
                    )),
              ],
            ),
            AppSpacing.gapM,
            Text(
              "Cette action effacera toutes les données de l'application (portefeuilles, transactions, paramètres) et la remettra à zéro comme lors de la première installation.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error.withValues(alpha: AppOpacities.veryHigh),
              ),
            ),
            AppSpacing.gapL,
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever, size: AppComponentSizes.iconSmall),
              label: const Text('Réinitialiser l\'application'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => _showResetDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error, size: AppComponentSizes.iconXLarge),
        title: const Text('Réinitialiser ?'),
        content: const Text(
          'Toutes vos données seront définitivement effacées. Action irréversible.',
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Réinitialiser'),
            onPressed: () {
              Provider.of<PortfolioProvider>(context, listen: false).resetAllData();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LaunchScreen()),
                    (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
