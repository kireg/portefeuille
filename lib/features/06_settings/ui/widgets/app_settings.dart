// lib/features/06_settings/ui/widgets/app_settings.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});
  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  late final TextEditingController _fmpKeyController;
  bool _obscureKey = true;
  bool _isKeyCurrentlySaved = false;

  // NOUVEAU : État pour la vérification de l'utilisation
  bool _isLoadingUsage = false;
  String? _apiUsageText;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _fmpKeyController = TextEditingController();

    // On utilise listen: false car on est dans initState
    final settingsProvider = context.read<SettingsProvider>();
    _isKeyCurrentlySaved = settingsProvider.hasFmpApiKey;

    // NOUVEAU : Récupérer l'ApiService
    _apiService = context.read<ApiService>();
  }

  @override
  void dispose() {
    _fmpKeyController.dispose();
    super.dispose();
  }

  /// Logique pour sauvegarder la clé
  Future<void> _saveKey() async {
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    final key = _fmpKeyController.text.trim();

    // Cacher le clavier
    FocusScope.of(context).unfocus();
    try {
      // 1. Sauvegarder la clé (ou la supprimer si le champ est vide)
      await provider.setFmpApiKey(key);
      // 2. Mettre à jour l'état local
      setState(() {
        _isKeyCurrentlySaved = provider.hasFmpApiKey;
        // 3. Vider le champ pour la sécurité
        _fmpKeyController.clear();
        // NOUVEAU : Réinitialiser le texte d'utilisation si la clé change
        _apiUsageText = null;
      });
      // 4. Afficher la confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(key.isEmpty
              ? "Clé API supprimée."
              : "Clé API sauvegardée en toute sécurité !"),
          backgroundColor: key.isEmpty ? Colors.orange[800] : Colors.green[600],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sauvegarde de la clé : $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // NOUVEAU : Logique pour vérifier l'utilisation de l'API
  Future<void> _checkApiUsage() async {
    setState(() {
      _isLoadingUsage = true;
      _apiUsageText = null;
    });

    final result = await _apiService.getApiUsage();

    if (mounted) {
      setState(() {
        _apiUsageText = result;
        _isLoadingUsage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilise Consumer car ces paramètres peuvent changer
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final theme = Theme.of(context);

        // On met à jour l'état si le provider change (ex: chargement initial)
        _isKeyCurrentlySaved = settingsProvider.hasFmpApiKey;

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

            // --- NOUVEAU BLOC POUR LA CLÉ API ---
            // Ce bloc ne s'affiche que si le mode en ligne est activé
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
                    const SizedBox(height: 4),
                    Text(
                      "Fournir une clé Financial Modeling Prep améliore la fiabilité de la récupération des prix.",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
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
                        const SizedBox(width: 8),
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
                            const SizedBox(height: 8),
                            // --- NOUVEAU : BOUTON ET AFFICHAGE UTILISATION ---
                            if (_isLoadingUsage)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else if (_apiUsageText != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  _apiUsageText!,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[400]),
                                ),
                              )
                            else
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _checkApiUsage,
                                child: const Text("Vérifier l'utilisation"),
                              ),
                            // --- FIN NOUVEAU ---
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            // --- FIN DU NOUVEAU BLOC ---

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
      },
    );
  }
}