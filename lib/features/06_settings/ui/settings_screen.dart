// lib/features/06_settings/ui/settings_screen.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/data/services/sync_log_export_service.dart';
import 'package:portefeuille/features/01_launch/ui/widgets/initial_setup_wizard.dart';
import 'package:portefeuille/features/01_launch/ui/launch_screen.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PortfolioProvider, SettingsProvider>(
      builder: (context, portfolioProvider, settingsProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppTheme.buildScreenTitle(
                context: context,
                title: 'Paramètres',
                centered: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _AppearanceCard(),
                  const SizedBox(height: 12),
                  // MODIFIÉ : Nouvelle carte pour les réglages généraux
                  _GeneralSettingsCard(),
                  const SizedBox(height: 12),
                  _PortfolioCard(),
                  const SizedBox(height: 12),
                  _OnlineModeCard(),
                  const SizedBox(height: 12),
                  _SyncLogsCard(),
                  const SizedBox(height: 12),
                  // SUPPRIMÉ : _UserLevelCard (fusionné dans _GeneralSettingsCard)
                  _DangerZoneCard(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// === APPARENCE ===
class _AppearanceCard extends StatelessWidget {
  final List<Color> _colorOptions = [
    const Color(0xFF00bcd4),
    Colors.blue,
    Colors.green,
    const Color(0xFFab47bc),
    Colors.orange,
    Colors.redAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return AppTheme.buildStyledCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.buildSectionHeader(
            context: context,
            icon: Icons.palette_outlined,
            title: 'Apparence',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: _colorOptions.map((color) {
              final isSelected = settingsProvider.appColor == color;
              return InkWell(
                onTap: () => settingsProvider.setAppColor(color),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : color.withOpacity(0.3),
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// === NOUVELLE CARTE : Préférences Générales ===
class _GeneralSettingsCard extends StatelessWidget {
  // Liste des devises de base supportées
  final List<String> _baseCurrencies = const ['EUR', 'USD', 'GBP', 'CHF', 'JPY', 'CAD'];

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    Theme.of(context);

    return AppTheme.buildStyledCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.buildSectionHeader(
            context: context,
            icon: Icons.tune_outlined,
            title: 'Préférences Générales',
          ),
          const SizedBox(height: 8),

          // 1. Sélection de la devise de base
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.currency_exchange_outlined),
            title: const Text('Devise de Base'),
            subtitle: const Text('Devise principale pour les totaux'),
            trailing: DropdownButton<String>(
              value: settingsProvider.baseCurrency,
              underline: const SizedBox(),
              onChanged: (val) {
                if (val != null) {
                  settingsProvider.setBaseCurrency(val);
                }
              },
              items: _baseCurrencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
            ),
          ),

          // 2. Sélection du niveau utilisateur
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: const Text('Niveau d\'utilisateur'),
            subtitle: const Text('Affiche des aides contextuelles'),
            trailing: DropdownButton<UserLevel>(
              value: settingsProvider.userLevel,
              underline: const SizedBox(),
              onChanged: (val) {
                if (val != null) settingsProvider.setUserLevel(val);
              },
              items: UserLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.toString().split('.').last),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// === PORTEFEUILLE ===
class _PortfolioCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final portfolioProvider = context.watch<PortfolioProvider>();
    final theme = Theme.of(context);

    return AppTheme.buildStyledCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.buildSectionHeader(
            context: context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Portefeuille',
          ),
          const SizedBox(height: 16),
          AppTheme.buildInfoContainer(
            context: context,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Actif', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        portfolioProvider.activePortfolio?.name ?? 'Aucun',
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (portfolioProvider.portfolios.length > 1)
                  PopupMenuButton<Portfolio>(
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'Changer',
                    onSelected: (portfolio) =>
                        portfolioProvider.setActivePortfolio(portfolio.id),
                    itemBuilder: (context) => portfolioProvider.portfolios
                        .map((p) => PopupMenuItem(
                      value: p,
                      child: Text(p.name),
                    ))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau'),
                onPressed: () =>
                    _showNewPortfolioDialog(context, portfolioProvider),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Renommer'),
                onPressed: portfolioProvider.activePortfolio == null
                    ? null
                    : () => _showRenameDialog(context, portfolioProvider),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Supprimer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: portfolioProvider.activePortfolio == null
                    ? null
                    : () => portfolioProvider
                    .deletePortfolio(portfolioProvider.activePortfolio!.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, PortfolioProvider provider) {
    final nameController =
    TextEditingController(text: provider.activePortfolio?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nouveau nom'),
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            child: const Text('Enregistrer'),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                provider.renameActivePortfolio(name);
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showNewPortfolioDialog(
      BuildContext context, PortfolioProvider provider) {
    final nameController = TextEditingController(text: "Nouveau Portefeuille");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau portefeuille'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comment créer votre portefeuille ?'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(ctx),
          ),
          OutlinedButton(
            child: const Text('Vide'),
            onPressed: () {
              provider.addNewPortfolio(nameController.text.trim().isEmpty
                  ? "Nouveau Portefeuille"
                  : nameController.text.trim());
              Navigator.pop(ctx);
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.assistant_outlined, size: 18),
            label: const Text('Assistant'),
            onPressed: () async {
              final name = nameController.text.trim().isEmpty
                  ? "Nouveau Portefeuille"
                  : nameController.text.trim();
              Navigator.pop(ctx);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InitialSetupWizard(portfolioName: name),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CARD: LOGS DE SYNCHRONISATION
// ============================================================================
class _SyncLogsCard extends StatelessWidget {
  const _SyncLogsCard();

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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      BuildContext context,
      String label,
      int value,
      IconData icon,
      Color color,
      ) {
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
    final successes =
        logs.where((log) => log.status == SyncStatus.synced).length;
    return {
      'total': logs.length,
      'success': successes,
      'errors': logs.length - successes,
    };
  }

  Future<void> _downloadLogs(
      BuildContext context,
      PortfolioProvider provider,
      ) async {
    try {
      final logs = provider.getAllSyncLogs();
      if (logs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun log à exporter'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final filePath = await SyncLogExportService.saveLogsToFile(logs);
      if (context.mounted) {
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
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearLogs(
      BuildContext context,
      PortfolioProvider provider,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer les logs ?'),
        content: const Text(
          'Tous les logs de synchronisation seront définitivement supprimés. '
              'Cette action est irréversible.',
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs effacés avec succès'),
          ),
        );
      }
    }
  }
}

// === MODE EN LIGNE ===
class _OnlineModeCard extends StatefulWidget {
  @override
  State<_OnlineModeCard> createState() => _OnlineModeCardState();
}

class _OnlineModeCardState extends State<_OnlineModeCard> {
  late TextEditingController _keyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey(SettingsProvider provider) async {
    final key = _keyController.text.trim();
    FocusScope.of(context).unfocus();
    try {
      await provider.setFmpApiKey(key);
      _keyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(key.isEmpty ? "Clé supprimée" : "Clé sauvegardée"),
            backgroundColor:
            key.isEmpty ? Colors.orange[800] : Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur : $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return AppTheme.buildStyledCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Mode en ligne', style: theme.textTheme.titleLarge),
              ),
              Switch.adaptive(
                value: settingsProvider.isOnlineMode,
                onChanged: (val) => settingsProvider.toggleOnlineMode(val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Prix en temps réel, analyse IA',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (settingsProvider.isOnlineMode) ...[
            const SizedBox(height: 20),
            Text('Clé API FMP (optionnel)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Text(
              'Améliore la fiabilité de la récupération des prix.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: "Entrer la clé",
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureKey
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Sauver'),
                  onPressed: () => _saveKey(settingsProvider),
                ),
              ],
            ),
            if (settingsProvider.hasFmpApiKey)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green[400]),
                    const SizedBox(width: 8),
                    Text(
                      'Clé enregistrée',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green[400],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// === ZONE DANGER ===
class _DangerZoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Text('Zone de danger',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.error,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Réinitialiser l\'application'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
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
            color: Theme.of(context).colorScheme.error, size: 48),
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
              Provider.of<PortfolioProvider>(context, listen: false)
                  .resetAllData();
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