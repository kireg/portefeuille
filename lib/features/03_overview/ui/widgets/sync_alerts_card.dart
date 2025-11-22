import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

class SyncAlertsCard extends StatelessWidget {
  const SyncAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final metadata = provider.allMetadata;

        // Filtrer les actifs
        final assetsWithErrors = metadata.entries
            .where((entry) => entry.value.syncStatus == SyncStatus.error)
            .toList();
        final neverSyncedCount = metadata.values
            .where((meta) => meta.syncStatus == SyncStatus.never)
            .length;
        final unsyncableCount = metadata.values
            .where((meta) => meta.syncStatus == SyncStatus.unsyncable)
            .length;

        if (assetsWithErrors.isEmpty && neverSyncedCount == 0 && unsyncableCount == 0) {
          return const SizedBox.shrink();
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  AppIcon(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Text('Alertes de synchronisation', style: AppTypography.h3),
                ],
              ),
              const SizedBox(height: AppDimens.paddingL),

              // 1. Jamais synchronisés
              if (neverSyncedCount > 0)
                _buildAlertItem(
                  icon: Icons.info_outline,
                  color: AppColors.primary,
                  title: '$neverSyncedCount actif(s) jamais synchronisé(s)',
                  subtitle: 'Lancez une synchronisation pour récupérer les prix.',
                ),

              // 2. Non synchronisables
              if (unsyncableCount > 0)
                _buildAlertItem(
                  icon: Icons.block,
                  color: AppColors.textTertiary,
                  title: '$unsyncableCount actif(s) non synchronisable(s)',
                  subtitle: 'Saisissez le prix manuellement (ex: Fonds euros).',
                ),

              // 3. Erreurs
              ...assetsWithErrors.map((entry) {
                return _buildAlertItem(
                  icon: Icons.error_outline,
                  color: AppColors.error,
                  title: entry.key,
                  subtitle: entry.value.syncErrorMessage ?? 'Erreur inconnue',
                  isError: true,
                );
              }),

              const SizedBox(height: AppDimens.paddingL),

              // Bouton d'action
              AppButton(
                label: provider.isProcessingInBackground ? 'TRAITEMENT...' : 'TOUT RESYNCHRONISER',
                isLoading: provider.isProcessingInBackground,
                onPressed: provider.isProcessingInBackground
                    ? null
                    : () => provider.synchroniserLesPrix(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyBold.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}