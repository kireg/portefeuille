// lib/features/06_settings/ui/widgets/sync_logs_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/data/services/sync_log_export_service.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

class SyncLogsCard extends StatelessWidget {
  const SyncLogsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portfolioProvider = context.watch<PortfolioProvider>();
    return AppTheme.buildStyledCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.buildSectionHeader(
            context: context,
            icon: Icons.history,
            title: 'Historique de synchronisation',
          ),
          const SizedBox(height: 16),
          AppTheme.buildInfoContainer(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Les logs de synchronisation enregistrent chaque tentative de mise à jour des prix.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '• Téléchargez l\'historique complet en CSV\n'
                      '• Analysez les erreurs récurrentes\n'
                      '• Maximum 1000 entrées conservées',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Statistiques des logs
          FutureBuilder<Map<String, int>>(
            future: _getLogStats(portfolioProvider),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final stats = snapshot.data!;
                return AppTheme.buildInfoContainer(
                  context: context,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        context,
                        'Total',
                        stats['total']!,
                        Icons.list_alt,
                        theme.colorScheme.primary,
                      ),
                      _buildStatColumn(
                        context,
                        'Succès',
                        stats['success']!,
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                      _buildStatColumn(
                        context,
                        'Erreurs',
                        stats['errors']!,
                        Icons.error_outline,
                        Colors.orange,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _downloadLogs(context, portfolioProvider),
                  icon: const Icon(Icons.download),
                  label: const Text('Télécharger CSV'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _clearLogs(context, portfolioProvider),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Effacer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, int value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<Map<String, int>> _getLogStats(PortfolioProvider provider) async {
    final logs = provider.getAllSyncLogs();
    final successes = logs.where((log) => log.status == SyncStatus.synced).length;
    return {
      'total': logs.length,
      'success': successes,
      'errors': logs.length - successes,
    };
  }

  Future<void> _downloadLogs(BuildContext context, PortfolioProvider provider) async {
    try {
      final logs = provider.getAllSyncLogs();
      if (logs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun log à exporter'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final filePath = await SyncLogExportService.saveLogsToFile(logs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logs exportés : ${filePath.split('\\').last}'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export : $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _clearLogs(BuildContext context, PortfolioProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer les logs ?'),
        content: const Text(
          'Tous les logs de synchronisation seront définitivement supprimés. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.clearAllSyncLogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs effacés avec succès')),
      );
    }
  }
}

