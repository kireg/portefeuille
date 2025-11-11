// lib/features/01_launch/ui/widgets/wizard_steps/step4_assets.dart
// Étape 4 : Ajout des actifs pour chaque compte

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/01_launch/data/wizard_models.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:intl/intl.dart';

class Step4Assets extends StatefulWidget {
  final List<WizardAccount> accounts;
  final List<WizardAsset> assets;
  final bool enableOnlineMode;
  final VoidCallback onAssetsChanged;

  const Step4Assets({
    super.key,
    required this.accounts,
    required this.assets,
    required this.enableOnlineMode,
    required this.onAssetsChanged,
  });

  @override
  State<Step4Assets> createState() => _Step4AssetsState();
}

class _Step4AssetsState extends State<Step4Assets> {
  final TextEditingController _tickerController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _pruController = TextEditingController();
  final TextEditingController _currentPriceController = TextEditingController();
  final TextEditingController _yieldController = TextEditingController();

  WizardAccount? _selectedAccount;
  AssetType? _selectedAssetType;
  DateTime _firstPurchaseDate = DateTime.now();

  // Pour la recherche de tickers
  List<TickerSuggestion> _suggestions = [];
  bool _isLoadingSearch = false;

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _selectedAccount = widget.accounts.first;
    }

    // Écouter les changements du ticker pour la recherche
    if (widget.enableOnlineMode) {
      _tickerController.addListener(_onTickerChanged);
    }
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _pruController.dispose();
    _currentPriceController.dispose();
    _yieldController.dispose();
    super.dispose();
  }

  void _onTickerChanged() {
    final query = _tickerController.text.trim();
    if (query.length >= 2) {
      // Debounce: attendre 500ms avant de lancer la recherche
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_tickerController.text.trim() == query && query.isNotEmpty) {
          _search(query);
        }
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  Future<void> _search(String query) async {
    if (!widget.enableOnlineMode) return;

    setState(() {
      _isLoadingSearch = true;
    });

    final apiService = context.read<ApiService>();
    final results = await apiService.searchTicker(query);

    if (mounted) {
      setState(() {
        _suggestions = results;
        _isLoadingSearch = false;
      });
    }
  }

  void _onSuggestionSelected(TickerSuggestion suggestion) {
    _tickerController.text = suggestion.ticker;
    _nameController.text = suggestion.name;
    setState(() {
      _suggestions = [];
    });

    // Récupérer le prix actuel et le mettre dans le champ "Prix actuel"
    if (widget.enableOnlineMode) {
      final apiService = context.read<ApiService>();
      apiService.getPrice(suggestion.ticker).then((priceResult) {
        if (priceResult.price != null && mounted) {
          _currentPriceController.text = priceResult.price!.toStringAsFixed(2);
          debugPrint(
              '💰 Prix actuel récupéré pour ${suggestion.ticker}: ${priceResult.price}€');
        } else {
          debugPrint('⚠️ Prix non disponible pour ${suggestion.ticker}');
        }
      }).catchError((error) {
        debugPrint(
            '❌ Erreur lors de la récupération du prix pour ${suggestion.ticker}: $error');
      });
    }
  }

  void _addAsset() {
    if (_selectedAccount == null) return;

    final ticker = _tickerController.text.trim();
    final name = _nameController.text.trim();
    final quantityStr = _quantityController.text.trim();
    final pruStr = _pruController.text.trim();
    final currentPriceStr = _currentPriceController.text.trim();
    final yieldStr = _yieldController.text.trim();

    if (ticker.isEmpty ||
        name.isEmpty ||
        quantityStr.isEmpty ||
        pruStr.isEmpty ||
        currentPriceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    final quantity = double.tryParse(quantityStr);
    final pru = double.tryParse(pruStr);
    final currentPrice = double.tryParse(currentPriceStr);
    // Convertir le rendement de pourcentage (3.0) en décimal (0.03)
    final yieldValue = yieldStr.isNotEmpty ? double.tryParse(yieldStr) : null;
    final estimatedYield = yieldValue != null ? yieldValue / 100 : null;

    if (quantity == null || quantity <= 0 || pru == null || pru <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La quantité et le PRU doivent être supérieurs à 0')),
      );
      return;
    }

    if (currentPrice == null || currentPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prix actuel doit être supérieur à 0')),
      );
      return;
    }

    final asset = WizardAsset(
      ticker: ticker,
      name: name,
      quantity: quantity,
      averagePrice: pru,
      currentPrice: currentPrice,
      estimatedYield: estimatedYield,
      firstPurchaseDate: _firstPurchaseDate,
      accountDisplayName: _selectedAccount!.displayName,
      type: _selectedAssetType,
    );

    widget.assets.add(asset);
    _selectedAccount!.assets.add(asset);

    // Réinitialiser le formulaire
    _tickerController.clear();
    _nameController.clear();
    _quantityController.clear();
    _pruController.clear();
    _currentPriceController.clear();
    _yieldController.clear();
    _selectedAssetType = null;
    _firstPurchaseDate = DateTime.now();

    widget.onAssetsChanged();
  }

  void _removeAsset(int index) {
    final asset = widget.assets[index];

    // Retirer aussi du compte parent
    final account = widget.accounts.firstWhere(
      (a) => a.displayName == asset.accountDisplayName,
    );
    account.assets.remove(asset);

    widget.assets.removeAt(index);
    widget.onAssetsChanged();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstPurchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _firstPurchaseDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            'Actifs 📈',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          Text(
            'Ajoutez vos actifs actuels (actions, ETF, crypto, etc.)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 24),

          // Formulaire d'ajout
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajouter un actif',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Sélection du compte
                  DropdownButtonFormField<WizardAccount>(
                    value: _selectedAccount,
                    decoration: const InputDecoration(
                      labelText: 'Compte',
                      prefixIcon: Icon(Icons.account_balance),
                      border: OutlineInputBorder(),
                    ),
                    items: widget.accounts.map((account) {
                      return DropdownMenuItem(
                        value: account,
                        child: Text(account.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedAccount = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ticker avec recherche
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _tickerController,
                        decoration: InputDecoration(
                          labelText: 'Ticker / Symbol *',
                          hintText: 'Ex: AAPL, BTC-USD...',
                          prefixIcon: const Icon(Icons.label),
                          suffixIcon: _isLoadingSearch
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),

                      // Suggestions de recherche
                      if (_suggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _suggestions[index];
                              return ListTile(
                                dense: true,
                                title: Text(suggestion.ticker),
                                subtitle: Text(
                                  '${suggestion.name} • ${suggestion.exchange}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _onSuggestionSelected(suggestion),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nom de l'actif
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'actif *',
                      hintText: 'Ex: Apple Inc., Bitcoin...',
                      prefixIcon: Icon(Icons.text_fields),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type d'actif (facultatif)
                  DropdownButtonFormField<AssetType>(
                    value: _selectedAssetType,
                    decoration: const InputDecoration(
                      labelText: 'Type d\'actif (optionnel)',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: AssetType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getAssetTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedAssetType = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantité et PRU sur la même ligne
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantité *',
                            hintText: '10',
                            prefixIcon: Icon(Icons.numbers),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,8}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _pruController,
                          decoration: const InputDecoration(
                            labelText: 'PRU (€) *',
                            hintText: '150.00',
                            prefixIcon: Icon(Icons.euro),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prix actuel
                  TextField(
                    controller: _currentPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Prix actuel (€) *',
                      hintText: '165.50',
                      helperText:
                          'Prix actuel de l\'actif (pour calcul de la valeur)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rendement annuel estimé (optionnel)
                  TextField(
                    controller: _yieldController,
                    decoration: const InputDecoration(
                      labelText: 'Rendement annuel estimé (%)',
                      hintText: '3.5',
                      helperText:
                          'Optionnel : dividendes ou intérêts annuels attendus',
                      prefixIcon: Icon(Icons.percent),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date du premier achat
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date du premier achat *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_firstPurchaseDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _addAsset,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter l\'actif'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Liste des actifs ajoutés
          if (widget.assets.isNotEmpty) ...[
            Text(
              'Actifs ajoutés (${widget.assets.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.assets.length,
              itemBuilder: (context, index) {
                final asset = widget.assets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.tertiaryContainer,
                      child: Text(
                        asset.ticker.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${asset.ticker} - ${asset.name}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${asset.accountDisplayName}\n${asset.quantity} × ${asset.averagePrice.toStringAsFixed(2)}€ = ${asset.totalValue.toStringAsFixed(2)}€',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () => _removeAsset(index),
                      tooltip: 'Supprimer',
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun actif ajouté',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Les actifs sont facultatifs, vous pouvez continuer sans en ajouter',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getAssetTypeLabel(AssetType type) {
    switch (type) {
      case AssetType.Stock:
        return 'Action';
      case AssetType.ETF:
        return 'ETF';
      case AssetType.Crypto:
        return 'Crypto';
      case AssetType.Bond:
        return 'Obligation';
      case AssetType.Cash:
        return 'Liquidités';
      case AssetType.Other:
        return 'Autre';
    }
  }
}
