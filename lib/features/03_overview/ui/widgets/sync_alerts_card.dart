// lib/features/03_overview/ui/widgets/sync_alerts_card.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';
// NOUVEL IMPORT
import 'package:portefeuille/features/00_app/models/background_activity.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';

class SyncAlertsCard extends StatelessWidget {
  const SyncAlertsCard({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final metadata = provider.allMetadata;

        // Filtrer les actifs avec erreur
        final assetsWithErrors = metadata.entries
            .where((entry) => entry.value.syncStatus == SyncStatus.error)
            .toList();

        // Compter les actifs jamais synchronisés
        final neverSyncedCount = metadata.values
            .where((meta) => meta.syncStatus == SyncStatus.never)
            .length;

        // Compter les actifs non synchronisables
        final unsyncableCount = metadata.values
            .where((meta) => meta.syncStatus == SyncStatus.unsyncable)
            .length;

        // Si aucune alerte, ne rien afficher
        if (assetsWithErrors.isEmpty &&
            neverSyncedCount == 0 &&
            unsyncableCount == 0) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTheme.buildSectionHeader(
              context: context,
              icon: Icons.warning_amber_rounded,
              title: 'Alertes de synchronisation',
            ),
            const SizedBox(height: 16),

            // Avertissement pour actifs jamais synchronisés
            if (neverSyncedCount > 0)
              AppTheme.buildInfoContainer(
                context: context,
                child: ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade400,
                  ),
                  title: Text(
                    '$neverSyncedCount actif${neverSyncedCount > 1 ? 's' : ''} jamais synchronisé${neverSyncedCount > 1 ? 's' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Ces actifs n\'ont pas encore été synchronisés avec une API de prix. '
                        'Lancez une synchronisation pour tenter de récupérer les prix automatiquement.',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.help_outline),
                    tooltip: 'Pourquoi ?',
                    onPressed: () => _showSyncExplanationDialog(context),
                  ),
                ),
              ),

            if (neverSyncedCount > 0 &&
                (assetsWithErrors.isNotEmpty || unsyncableCount > 0))
              const SizedBox(height: 8),

            // Avertissement pour actifs non synchronisables
            if (unsyncableCount > 0)
              AppTheme.buildInfoContainer(
                context: context,
                child: ListTile(
                  leading: Icon(
                    Icons.block,
                    color: Colors.grey.shade600,
                  ),
                  title: Text(
                    '$unsyncableCount actif${unsyncableCount > 1 ? 's' : ''} non synchronisable${unsyncableCount > 1 ? 's' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Ces actifs (fonds en euros, produits non cotés) ne peuvent pas être synchronisés automatiquement. '
                        'Vous devez saisir le prix manuellement.',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.help_outline),
                    tooltip: 'Pourquoi ?',
                    onPressed: () => _showUnsyncableExplanationDialog(context),
                  ),
                ),
              ),

            if ((neverSyncedCount > 0 || unsyncableCount > 0) &&
                assetsWithErrors.isNotEmpty)
              const SizedBox(height: 8),

            // Liste des erreurs
            if (assetsWithErrors.isNotEmpty)
              ...assetsWithErrors.map((entry) {
                final ticker = entry.key;
                final meta = entry.value;
                final explanation = _getErrorExplanation(meta.syncErrorMessage);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: AppTheme.buildInfoContainer(
                    context: context,
                    child: ExpansionTile(
                      leading: Icon(
                        Icons.error_outline,
                        color: Colors.orange.shade700,
                      ),
                      title: Text(
                        ticker,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        explanation.shortMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        meta.lastSyncAttempt != null
                            ? _formatDate(meta.lastSyncAttempt!)
                            : '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pourquoi cette erreur ?',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                explanation.detailedExplanation,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Solutions possibles :',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...explanation.solutions
                                  .map((solution) => Padding(
                                padding:
                                const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text('• '),
                                    Expanded(child: Text(solution)),
                                  ],
                                ),
                              )),
                              if (meta.syncErrorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Erreur technique :',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  meta.syncErrorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 12),

            // Bouton Resynchroniser tout
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                // --- MODIFIÉ : Utilise le nouveau getter ---
                onPressed: provider.isProcessingInBackground
                    ? null
                    : () {
                  provider.synchroniserLesPrix();
                },
                icon: provider.isProcessingInBackground
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.sync),
                label: Text(
                  provider.activity is Syncing
                      ? 'Synchronisation...'
                      : provider.activity is Recalculating
                      ? 'Recalcul...'
                      : 'Resynchroniser tout',
                ),
                // --- FIN MODIFICATION ---
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inHours < 1) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inDays < 1) {
      return 'Il y a ${diff.inHours}h';
    } else {
      return 'Il y a ${diff.inDays}j';
    }
  }

  /// Analyse le message d'erreur et retourne une explication pédagogique
  _ErrorExplanation _getErrorExplanation(String? errorMessage) {
    if (errorMessage == null) {
      return _ErrorExplanation(
        shortMessage: 'Erreur inconnue',
        detailedExplanation:
        'Une erreur s\'est produite mais aucun détail n\'est disponible.',
        solutions: ['Réessayez la synchronisation'],
      );
    }

    final lowerError = errorMessage.toLowerCase();

    // Erreur réseau
    if (lowerError.contains('socketexception') ||
        lowerError.contains('hôte inconnu') ||
        lowerError.contains('network') ||
        lowerError.contains('connection')) {
      return _ErrorExplanation(
        shortMessage: 'Problème de connexion Internet',
        detailedExplanation:
        'L\'application n\'a pas pu se connecter aux serveurs de données financières. '
            'Cela peut être dû à un problème de connexion Internet ou à une indisponibilité temporaire du service.',
        solutions: [
          'Vérifiez votre connexion Internet',
          'Réessayez dans quelques minutes',
          'Si le problème persiste, le service API est peut-être temporairement indisponible',
        ],
      );
    }

    // Ticker introuvable
    if (lowerError.contains('not found') ||
        lowerError.contains('no data') ||
        lowerError.contains('introuvable')) {
      return _ErrorExplanation(
        shortMessage: 'Actif introuvable dans les bases de données',
        detailedExplanation:
        'Le ticker (symbole boursier) de cet actif n\'existe pas dans les bases de données des APIs utilisées '
            '(Yahoo Finance, FMP). Cela arrive souvent pour :\n'
            '• Les fonds en euros (pas cotés en bourse)\n'
            '• Les actifs avec un ticker incorrect\n'
            '• Les produits non cotés publiquement',
        solutions: [
          'Vérifiez que le ticker est correct (ex: AAPL pour Apple, MSFT pour Microsoft)',
          'Pour les fonds en euros ou actifs non cotés, saisissez le prix manuellement',
          'Certains actifs français nécessitent un suffixe (.PA pour Paris)',
        ],
      );
    }

    // Limite API atteinte
    if (lowerError.contains('limit') ||
        lowerError.contains('quota') ||
        lowerError.contains('rate')) {
      return _ErrorExplanation(
        shortMessage: 'Limite d\'utilisation de l\'API atteinte',
        detailedExplanation:
        'Vous avez atteint la limite quotidienne de requêtes autorisées par l\'API gratuite. '
            'Les APIs gratuites ont généralement une limite de 250 à 500 requêtes par jour.',
        solutions: [
          'Attendez demain pour que le quota se réinitialise',
          'Configurez une clé API premium dans les Paramètres (si disponible)',
          'Saisissez les prix manuellement en attendant',
        ],
      );
    }

    // Erreur API générique
    return _ErrorExplanation(
      shortMessage: 'Erreur lors de la récupération des données',
      detailedExplanation:
      'Une erreur technique s\'est produite lors de la communication avec l\'API de données financières. '
          'Consultez l\'erreur technique ci-dessous pour plus de détails.',
      solutions: [
        'Réessayez la synchronisation',
        'Vérifiez que le ticker de l\'actif est correct',
        'Si le problème persiste, saisissez le prix manuellement',
      ],
    );
  }

  /// Affiche un dialog expliquant le fonctionnement de la synchronisation
  void _showSyncExplanationDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('💡 Comment fonctionne la synchronisation ?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Les différents statuts :',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusExplanation(
                '✅',
                'Synchronisé',
                'L\'actif a été synchronisé avec succès. Le prix affiché provient d\'une API de données financières.',
              ),
              const SizedBox(height: 8),
              _buildStatusExplanation(
                '⚠️',
                'Erreur de synchronisation',
                'Une erreur s\'est produite lors de la tentative de synchronisation. '
                    'Consultez les détails pour comprendre le problème.',
              ),
              const SizedBox(height: 8),
              _buildStatusExplanation(
                '✏️',
                'Prix manuel',
                'Le prix a été saisi manuellement. L\'application ne tentera pas de le remplacer automatiquement.',
              ),
              const SizedBox(height: 8),
              _buildStatusExplanation(
                '⭕',
                'Jamais synchronisé',
                'Aucune tentative de synchronisation n\'a encore été effectuée pour cet actif.',
              ),
              const SizedBox(height: 8),
              _buildStatusExplanation(
                '🚫',
                'Non synchronisable',
                'Cet actif ne peut pas être synchronisé automatiquement (fonds en euros, produit non coté). '
                    'Vous devez saisir le prix manuellement.',
              ),
              const SizedBox(height: 16),
              Text(
                'APIs utilisées :',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. FMP (Financial Modeling Prep) - si clé API configurée\n'
                    '2. Yahoo Finance - API de secours gratuite\n\n'
                    'Note : Certains actifs (fonds en euros, produits non cotés) '
                    'ne peuvent pas être synchronisés automatiquement.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compris !'),
          ),
        ],
      ),
    );
  }

  /// Dialog expliquant pourquoi certains actifs ne peuvent pas être synchronisés
  void _showUnsyncableExplanationDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🚫 Actifs non synchronisables'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pourquoi certains actifs ne peuvent-ils pas être synchronisés ?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Les APIs de données financières (Yahoo Finance, FMP) ne contiennent que des actifs '
                    'cotés publiquement sur les marchés boursiers.\n\n'
                    'Les actifs suivants ne sont PAS synchronisables :\n'
                    '• Fonds en euros (contrats d\'assurance-vie)\n'
                    '• Produits structurés non cotés\n'
                    '• Parts de SCPI\n'
                    '• Comptes à terme\n'
                    '• Tout actif sans ticker boursier public\n\n'
                    'Pour ces actifs, vous devez :\n'
                    '1. Consulter votre relevé bancaire/d\'assurance\n'
                    '2. Saisir le prix manuellement dans l\'application\n'
                    '3. Le prix sera marqué comme "Manuel" (✏️) et ne sera jamais écrasé automatiquement',
              ),
              const SizedBox(height: 16),
              Text(
                'Comment saisir un prix manuellement ?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Allez dans l\'onglet "Journal" → "Synthèse Actifs"\n'
                    '2. Cliquez sur le prix actuel de l\'actif\n'
                    '3. Saisissez le nouveau prix\n'
                    '4. Validez : l\'actif sera marqué comme "Manuel"',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compris !'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusExplanation(
      String icon, String title, String explanation) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(explanation),
            ],
          ),
        ),
      ],
    );
  }
}

/// Classe pour structurer les explications d'erreur
class _ErrorExplanation {
  final String shortMessage;
  final String detailedExplanation;
  final List<String> solutions;
  _ErrorExplanation({
    required this.shortMessage,
    required this.detailedExplanation,
    required this.solutions,
  });
}