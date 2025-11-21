import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/data/services/sync_log_export_service.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';

class SyncLogsCard extends StatelessWidget {
  const SyncLogsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final logs = provider.getAllSyncLogs();
    final successes = logs.where((log) => log.status == SyncStatus.synced).length;
    final errors = logs.length - successes;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const AppIcon(icon: Icons.history, color: AppColors.textSecondary),
              const SizedBox(width: AppDimens.paddingM),
              Text('Historique Synchro', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: AppDimens.paddingL),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Total', logs.length.toString(), AppColors.primary),
              _buildStat('Succès', successes.toString(), AppColors.success),
              _buildStat('Erreurs', errors.toString(), AppColors.error),
            ],
          ),

          const SizedBox(height: AppDimens.paddingL),

          // Actions
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'CSV',
                  icon: Icons.download,
                  type: AppButtonType.secondary,
                  onPressed: () => _downloadLogs(context, logs),
                ),
              ),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: AppButton(
                  label: 'Vider',
                  icon: Icons.delete_outline,
                  type: AppButtonType.secondary,
                  onPressed: () => provider.clearAllSyncLogs(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTypography.h2.copyWith(color: color)),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Future<void> _downloadLogs(BuildContext context, List<dynamic> logs) async {
    if (logs.isEmpty) return;
    // Cast explicite pour la méthode de service
    await SyncLogExportService.saveLogsToFile(logs.cast());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs exportés')));
    }
  }
}