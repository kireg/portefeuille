import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/01_launch/data/wizard_models.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

class AddAssetDialog extends StatefulWidget {
  final WizardAsset? initialAsset;
  final bool enableOnlineMode;

  const AddAssetDialog({
    super.key,
    this.initialAsset,
    this.enableOnlineMode = false,
  });

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tickerController;
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _avgPriceController;
  late TextEditingController _currentPriceController;
  late TextEditingController _yieldController;
  AssetType _type = AssetType.Stock;
  DateTime _purchaseDate = DateTime.now();
  bool _isLoadingPrice = false;

  @override
  void initState() {
    super.initState();
    final asset = widget.initialAsset;
    _tickerController = TextEditingController(text: asset?.ticker ?? '');
    _nameController = TextEditingController(text: asset?.name ?? '');
    _quantityController =
        TextEditingController(text: asset?.quantity.toString() ?? '');
    _avgPriceController =
        TextEditingController(text: asset?.averagePrice.toString() ?? '');
    _currentPriceController =
        TextEditingController(text: asset?.currentPrice.toString() ?? '');
    
    // Conversion du rendement décimal en pourcentage pour l'affichage (ex: 0.03 -> 3)
    String yieldText = '';
    if (asset?.estimatedYield != null) {
      yieldText = (asset!.estimatedYield! * 100).toString();
      // Enlever le .0 si c'est un entier
      if (yieldText.endsWith('.0')) {
        yieldText = yieldText.substring(0, yieldText.length - 2);
      }
    }
    _yieldController = TextEditingController(text: yieldText);

    if (asset != null) {
      _type = asset.type ?? AssetType.Stock;
      _purchaseDate = asset.firstPurchaseDate;
    }
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _avgPriceController.dispose();
    _currentPriceController.dispose();
    _yieldController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSetPrice(String ticker) async {
    if (!widget.enableOnlineMode) return;

    setState(() => _isLoadingPrice = true);
    try {
      final apiService = context.read<ApiService>();
      final settings = context.read<SettingsProvider>();
      final targetCurrency = settings.baseCurrency;

      final priceResult = await apiService.getPrice(ticker);
      
      if (priceResult.price != null) {
        double price = priceResult.price!;
        String currency = priceResult.currency;

        // Conversion si nécessaire
        if (currency != targetCurrency) {
          try {
            final rate = await apiService.getExchangeRate(currency, targetCurrency);
            price = price * rate;
          } catch (e) {
            debugPrint('Erreur conversion devise: $e');
            // On garde le prix original mais on pourrait avertir l'utilisateur
          }
        }

        if (mounted) {
          setState(() {
            _currentPriceController.text = price.toStringAsFixed(2);
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur récupération prix: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPrice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = context.read<ApiService>();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initialAsset == null
                      ? 'Ajouter un actif'
                      : 'Modifier l\'actif',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                
                // Ticker & Type
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TypeAheadField<TickerSuggestion>(
                        controller: _tickerController,
                        builder: (context, controller, focusNode) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Symbole (Ticker)',
                              hintText: 'ex: AAPL, CW8.PA',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _isLoadingPrice 
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 16, 
                                      height: 16, 
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : null,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) =>
                                v?.isEmpty == true ? 'Requis' : null,
                          );
                        },
                        suggestionsCallback: (pattern) async {
                          if (pattern.length < 2) return [];
                          return await apiService.searchTicker(pattern);
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Text(suggestion.ticker),
                            subtitle: Text(
                                '${suggestion.name} (${suggestion.exchange})'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (suggestion.price != null)
                                  Text(
                                    '${suggestion.price} ${suggestion.currency}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                Text(suggestion.currency, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        },
                        onSelected: (suggestion) {
                          _tickerController.text = suggestion.ticker;
                          _nameController.text = suggestion.name;
                          _fetchAndSetPrice(suggestion.ticker);
                        },
                        emptyBuilder: (context) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Aucun résultat trouvé'),
                        ),
                        loadingBuilder: (context) => const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<AssetType>(
                        value: _type,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: AssetType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Nom
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'actif',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: 24),
                
                // Quantité & Prix
                Text('Position', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantité',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                        ],
                        validator: (v) =>
                            (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Inv.' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _avgPriceController,
                        decoration: const InputDecoration(
                          labelText: 'PRU (Prix Moyen)',
                          border: OutlineInputBorder(),
                          helperText: 'Prix d\'achat unitaire',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) =>
                            (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Inv.' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Prix Actuel & Rendement
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currentPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Prix Actuel',
                          border: OutlineInputBorder(),
                          helperText: 'Pour valorisation',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) =>
                            (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Inv.' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _yieldController,
                        decoration: const InputDecoration(
                          labelText: 'Rendement (%)',
                          border: OutlineInputBorder(),
                          helperText: 'Optionnel',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Date de premier achat
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _purchaseDate,
                      firstDate: DateTime(1970),
                      lastDate: DateTime.now(),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (picked != null) {
                      setState(() => _purchaseDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de premier achat',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_purchaseDate.day.toString().padLeft(2, '0')}/${_purchaseDate.month.toString().padLeft(2, '0')}/${_purchaseDate.year}',
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Valider'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Conversion du rendement en décimal (ex: 3% -> 0.03)
      double? yieldValue;
      if (_yieldController.text.isNotEmpty) {
        final val = double.tryParse(_yieldController.text);
        if (val != null) {
          yieldValue = val / 100.0;
        }
      }

      final asset = WizardAsset(
        id: widget.initialAsset?.id,
        ticker: _tickerController.text.trim(),
        name: _nameController.text.trim(),
        type: _type,
        quantity: double.parse(_quantityController.text),
        averagePrice: double.parse(_avgPriceController.text),
        currentPrice: double.parse(_currentPriceController.text),
        estimatedYield: yieldValue,
        firstPurchaseDate: _purchaseDate,
      );
      Navigator.pop(context, asset);
    }
  }
}
