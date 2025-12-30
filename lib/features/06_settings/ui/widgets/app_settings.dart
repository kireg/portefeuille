// lib/features/06_settings/ui/widgets/app_settings.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart'; // NOUVEL IMPORT
import 'package:portefeuille/core/data/models/asset_metadata.dart'; // NOUVEL IMPORT
import 'package:intl/intl.dart'; // NOUVEL IMPORT

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});
  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  late final TextEditingController _fmpKeyController;
  bool _obscureKey = true;
  bool _isKeyCurrentlySaved = false;

  @override
  void initState() {
    super.initState();
    _fmpKeyController = TextEditingController();
    final settingsProvider = context.read<SettingsProvider>();
    _isKeyCurrentlySaved = settingsProvider.hasFmpApiKey;
  }

  @override
  void dispose() {
    _fmpKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    final key = _fmpKeyController.text.trim();

    FocusScope.of(context).unfocus();
    try {
      await provider.setFmpApiKey(key);
      if (!mounted) return;
      setState(() {
        _isKeyCurrentlySaved = provider.hasFmpApiKey;
        _fmpKeyController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(key.isEmpty
              ? "Clé API supprimée."
              : "Clé API sauvegardée en toute sécurité !"),
          backgroundColor: key.isEmpty ? Colors.orange[800] : Colors.green[600],
          showCloseIcon: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sauvegarde de la clé : $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
          showCloseIcon: true,
        ),
      );
    }
  }

  // --- NOUVEAU : Widget pour le tableau de statut ---
  Widget _buildMetadataStatusTable(
      BuildContext context, List<AssetMetadata> metadataList) {
    if (metadataList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Trier par ticker
    metadataList.sort((a, b) => a.ticker.compareTo(b.ticker));

    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Statut des Prix",
            style: theme.textTheme.titleSmall,
          ),
          AppSpacing.gapS,
          // Conteneur pour le défilement horizontal si nécessaire
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 32,
              headingRowHeight: 40,
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor, width: 1),
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              columns: [
                DataColumn(
                    label: Text('Actif', style: theme.textTheme.labelMedium)),
                DataColumn(
                    label: Text('Dernière MàJ',
                        style: theme.textTheme.labelMedium)),
              ],
              rows: metadataList.map((metadata) {
                return DataRow(
                  cells: [
                    DataCell(Text(metadata.ticker, style: textStyle)),
                    DataCell(Text(
                      DateFormat('dd/MM/yy HH:mm').format(metadata.lastUpdated),
                      style: textStyle,
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  // --- FIN NOUVEAU ---

  @override
  Widget build(BuildContext context) {
    // Écoute les SettingsProvider
    final settingsProvider = context.watch<SettingsProvider>();
    // Écoute le PortfolioProvider pour le tableau de métadonnées
    final portfolioProvider = context.watch<PortfolioProvider>();

    final theme = Theme.of(context);
    _isKeyCurrentlySaved = settingsProvider.hasFmpApiKey;

    // Récupérer les métadonnées pour le tableau
    final allMetadata = portfolioProvider.allMetadata.values.toList();

    return Column(
      children: [
        SwitchListTile.adaptive(
          title: const Text('Mode en ligne'),
          subtitle: const Text('Mise à jour des prix, analyse IA, etc.'),
          value: settingsProvider.isOnlineMode,
          onChanged: (bool value) {
            settingsProvider.toggleOnlineMode(value);
          },
          activeTrackColor: Theme.of(context).colorScheme.primary,
        ),

        // --- NOUVEAU : Insertion du tableau ---
        if (settingsProvider.isOnlineMode)
          _buildMetadataStatusTable(context, allMetadata),
        // --- FIN NOUVEAU ---

        // Bloc pour la clé API
        if (settingsProvider.isOnlineMode)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Clé API FMP (Optionnel)",
                  style: theme.textTheme.titleSmall,
                ),
                AppSpacing.gapXs,
                Text(
                  "Fournir une clé Financial Modeling Prep améliore la fiabilité de la récupération des prix.",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                AppSpacing.gap12,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fmpKeyController,
                        obscureText: _obscureKey,
                        decoration: InputDecoration(
                          labelText: "Entrer/Mettre à jour la clé",
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureKey
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () {
                              setState(() {
                                _obscureKey = !_obscureKey;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.gapHorizontalSmall,
                    IconButton.filledTonal(
                      icon: const Icon(Icons.save_outlined),
                      tooltip: "Sauvegarder la clé",
                      onPressed: _saveKey,
                    ),
                  ],
                ),
                if (_isKeyCurrentlySaved)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "✓ Une clé API est actuellement enregistrée.",
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.green[400]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        const Divider(),

        ListTile(
          title: const Text('Niveau d\'utilisateur'),
          trailing: DropdownButton<UserLevel>(
            value: settingsProvider.userLevel,
            onChanged: (UserLevel? newValue) {
              if (newValue != null) {
                settingsProvider.setUserLevel(newValue);
              }
            },
            items: UserLevel.values
                .map<DropdownMenuItem<UserLevel>>((UserLevel value) {
              return DropdownMenuItem<UserLevel>(
                value: value,
                child: Text(value.toString().split('.').last),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}