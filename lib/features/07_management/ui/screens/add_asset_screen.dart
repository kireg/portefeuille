// lib/features/07_management/ui/screens/add_asset_screen.dart

import 'dart:async'; // NOUVEL IMPORT
import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset.dart';
// --- NOUVEAUX IMPORTS ---
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
// --- FIN NOUVEAUX IMPORTS ---
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddAssetScreen extends StatefulWidget {
  final String accountId;
  final void Function(Asset)? onAssetCreated;

  const AddAssetScreen({
    super.key,
    required this.accountId,
    this.onAssetCreated,
  });

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Contrôleurs
  final _nameController = TextEditingController();
  final _tickerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _avgPriceController = TextEditingController();
  final _currentPriceController = TextEditingController();
  final _yieldController = TextEditingController(text: "0.0");

  // --- NOUVEAU : Logique de recherche ---
  Timer? _debounce;
  List<TickerSuggestion> _suggestions = [];
  bool _isLoadingSearch = false;
  late final ApiService _apiService;
  late final SettingsProvider _settingsProvider;
  // --- FIN NOUVEAU ---

  @override
  void initState() {
    super.initState();
    // Récupérer les services
    _apiService = context.read<ApiService>();
    _settingsProvider = context.read<SettingsProvider>();

    // Écouter les changements sur le champ Ticker
    _tickerController.addListener(_onTickerChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tickerController.removeListener(_onTickerChanged); // NOUVEAU
    _tickerController.dispose();
    _quantityController.dispose();
    _avgPriceController.dispose();
    _currentPriceController.dispose();
    _yieldController.dispose();
    _debounce?.cancel(); // NOUVEAU
    super.dispose();
  }

  // --- NOUVEAU : Logique de Debounce pour la recherche ---
  void _onTickerChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _tickerController.text.trim();
      if (query.length < 2) {
        setState(() {
          _suggestions = [];
          _isLoadingSearch = false;
        });
        return;
      }

      // --- CORRECTION BUG ---
      // On vérifie le mode en ligne AVANT de lancer la recherche
      if (_settingsProvider.isOnlineMode) {
        _search(query);
      } else {
        setState(() {
          _suggestions = [];
          _isLoadingSearch = false;
        });
      }
      // --- FIN CORRECTION ---
    });
  }

  Future<void> _search(String query) async {
    if (!_settingsProvider.isOnlineMode) return; // Sécurité supplémentaire

    setState(() {
      _isLoadingSearch = true;
    });

    final results = await _apiService.searchTicker(query);

    if (mounted) {
      setState(() {
        _suggestions = results;
        _isLoadingSearch = false;
      });
    }
  }

  /// Lorsqu'un utilisateur clique sur une suggestion
  void _onSuggestionSelected(TickerSuggestion suggestion) {
    // --- CORRECTION ---
    // On retire temporairement le listener pour éviter que la mise à jour
    // du champ ne déclenche une nouvelle recherche.
    _tickerController.removeListener(_onTickerChanged);
    // --- FIN CORRECTION ---

    // 1. Remplir les champs
    _tickerController.text = suggestion.ticker;
    _nameController.text = suggestion.name;

    // 2. Effacer les suggestions et le focus
    setState(() {
      _suggestions = [];
    });
    FocusScope.of(context).unfocus();

    // 3. Tenter de récupérer le prix actuel (seulement si en ligne)
    if (_settingsProvider.isOnlineMode) {
      _apiService.getPrice(suggestion.ticker).then((price) {
        if (price != null && mounted) {
          _currentPriceController.text = price.toStringAsFixed(2);
          // Si le PRU est vide, on le pré-remplit aussi
          if (_avgPriceController.text.isEmpty) {
            _avgPriceController.text = price.toStringAsFixed(2);
          }
        }
      });
    }

    // --- CORRECTION ---
    // On rattache le listener
    _tickerController.addListener(_onTickerChanged);
    // --- FIN CORRECTION ---
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newAsset = Asset(
        id: _uuid.v4(),
        name: _nameController.text,
        ticker: _tickerController.text.toUpperCase(),
        // On s'assure de gérer la virgule et le point
        quantity:
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0,
        averagePrice:
        double.tryParse(_avgPriceController.text.replaceAll(',', '.')) ?? 0,
        currentPrice:
        double.tryParse(_currentPriceController.text.replaceAll(',', '.')) ??
            0,
        estimatedAnnualYield:
        (double.tryParse(_yieldController.text.replaceAll(',', '.')) ?? 0) /
            100.0,
      );

      if (widget.onAssetCreated != null) {
        widget.onAssetCreated!(newAsset);
      } else {
        Provider.of<PortfolioProvider>(context, listen: false)
            .addAsset(widget.accountId, newAsset);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 16.0,
        left: 16.0,
        right: 16.0,
        bottom: keyboardPadding + 16.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajouter un Actif',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // --- MODIFIÉ : Champ Ticker (avec recherche) ---
            TextFormField(
              controller: _tickerController,
              decoration: InputDecoration(
                labelText: 'Ticker (ex: AAPL) ou ISIN',
                suffixIcon: _isLoadingSearch && _settingsProvider.isOnlineMode
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                    : null,
              ),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            // --- NOUVEAU : Affichage des suggestions ---
            if (_suggestions.isNotEmpty)
              SizedBox(
                height: 150, // Hauteur fixe pour la liste de suggestions
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(suggestion.name),
                      subtitle:
                      Text("${suggestion.ticker} (${suggestion.exchange})"),
                      onTap: () => _onSuggestionSelected(suggestion),
                    );
                  },
                ),
              ),
            // --- FIN NOUVEAU ---

            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nom (ex: Apple)'),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantité'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _avgPriceController,
              decoration: const InputDecoration(
                  labelText: 'Prix de Revient Unitaire (PRU)'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentPriceController,
              decoration: const InputDecoration(labelText: 'Prix Actuel'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _yieldController,
              decoration: const InputDecoration(
                  labelText: 'Rendement Annuel Estimé (%)', suffixText: '%'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Enregistrer'),
            )
          ],
        ),
      ),
    );
  }
}