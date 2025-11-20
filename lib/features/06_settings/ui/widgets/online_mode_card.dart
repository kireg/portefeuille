import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

class OnlineModeCard extends StatefulWidget {
  const OnlineModeCard({super.key});
  @override
  State<OnlineModeCard> createState() => _OnlineModeCardState();
}

class _OnlineModeCardState extends State<OnlineModeCard> {
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

  // --- Tableau de statut des prix (Importé de app_settings.dart) ---


  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final portfolioProvider = context.watch<PortfolioProvider>(); // Nécessaire pour les métadonnées
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
            'Prix en temps réel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          if (settingsProvider.isOnlineMode) ...[
            // Affichage du tableau de statut
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            Text('Clé API FMP (optionnel)',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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