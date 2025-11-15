// lib/features/06_settings/ui/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/features/01_launch/ui/widgets/initial_setup_wizard.dart';
import 'package:portefeuille/features/01_launch/ui/launch_screen.dart';
import 'package:intl/intl.dart';
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
                  _PortfolioCard(),
                  const SizedBox(height: 12),
                  _OnlineModeCard(),
                  const SizedBox(height: 12),
                  _UserLevelCard(),
                  const SizedBox(height: 12),
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
                onPressed: () => _showNewPortfolioDialog(context, portfolioProvider),
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
                    : () => portfolioProvider.deletePortfolio(
                    portfolioProvider.activePortfolio!.id),
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

  void _showNewPortfolioDialog(BuildContext context, PortfolioProvider provider) {
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
            backgroundColor: key.isEmpty ? Colors.orange[800] : Colors.green[600],
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
    final portfolioProvider = context.watch<PortfolioProvider>();
    final theme = Theme.of(context);
    final allMetadata = portfolioProvider.allMetadata.values.toList()
      ..sort((a, b) => a.ticker.compareTo(b.ticker));

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
            if (allMetadata.isNotEmpty) ...[
              Text('Statut des prix',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 12),
              AppTheme.buildInfoContainer(
                context: context,
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allMetadata.length,
                  separatorBuilder: (_, __) => Divider(height: 1, indent: 16),
                  itemBuilder: (_, i) {
                    final meta = allMetadata[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          meta.ticker[0],
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(meta.ticker, style: theme.textTheme.bodyMedium),
                      trailing: Text(
                        DateFormat('dd/MM HH:mm').format(meta.lastUpdated),
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
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
                        onPressed: () => setState(() => _obscureKey = !_obscureKey),
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
                    Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
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

// === NIVEAU UTILISATEUR ===
class _UserLevelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return AppTheme.buildStyledCard(
      context: context,
      child: Row(
        children: [
          Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Niveau d\'utilisateur',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          DropdownButton<UserLevel>(
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
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
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