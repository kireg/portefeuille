// lib/features/07_management/ui/screens/edit_transaction_screen.dart
// NOUVEAU FICHIER

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';
// Imports pour la recherche
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

class EditTransactionScreen extends StatefulWidget {
  final Transaction existingTransaction;

  const EditTransactionScreen({super.key, required this.existingTransaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  // final _uuid = const Uuid(); // Pas besoin de UUID pour une mise à jour

  // État du formulaire
  Account? _selectedAccount;
  late TransactionType _selectedType;
  late DateTime _selectedDate;
  AssetType _selectedAssetType = AssetType.Stock;

  // Contrôleurs
  final _amountController = TextEditingController();
  final _tickerController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _feesController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  List<Account> _availableAccounts = [];

  // Logique de recherche
  Timer? _debounce;
  List<TickerSuggestion> _suggestions = [];
  bool _isLoadingSearch = false;
  late final ApiService _apiService;
  late final SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();

    // --- INITIALISATION DES SERVICES ---
    _apiService = context.read<ApiService>();
    _settingsProvider = context.read<SettingsProvider>();
    // NE PAS AJOUTER LE LISTENER ICI

    // --- CHARGEMENT DES COMPTES ---
    final portfolio = context.read<PortfolioProvider>().activePortfolio;
    if (portfolio != null) {
      _availableAccounts =
          portfolio.institutions.expand((inst) => inst.accounts).toList();
    }

    // --- PRÉ-REMPLISSAGE DU FORMULAIRE ---
    final tx = widget.existingTransaction;

    try {
      _selectedAccount = _availableAccounts.firstWhere(
            (acc) => acc.id == tx.accountId,
      );
    } catch (e) {
      _selectedAccount =
      _availableAccounts.isNotEmpty ? _availableAccounts.first : null;
    }

    _selectedType = tx.type;
    _selectedDate = tx.date;
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);

    _notesController.text = tx.notes;
    _feesController.text = tx.fees.toStringAsFixed(2);
    _tickerController.text = tx.assetTicker ?? '';
    _nameController.text = tx.assetName ?? '';
    _quantityController.text = tx.quantity?.toString() ?? '';
    _priceController.text = tx.price?.toString() ?? '';
    _amountController.text = tx.amount.abs().toStringAsFixed(2);
    _selectedAssetType = tx.assetType ?? AssetType.Stock;

    // --- MODIFICATION ---
    // Ajoute le listener APRÈS avoir défini le texte initial
    _tickerController.addListener(_onTickerChanged);
    // --- FIN MODIFICATION ---
  }

  @override
  void dispose() {
    // ... (dispose de tous les contrôleurs) ...
    _amountController.dispose();
    _tickerController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _feesController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _tickerController.removeListener(_onTickerChanged);
    _debounce?.cancel();
    super.dispose();
  }

  // --- LOGIQUE DE RECHERCHE (identique à AddTransactionScreen) ---
  void _onTickerChanged() {
    if (_selectedType != TransactionType.Buy &&
        _selectedType != TransactionType.Sell) {
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _tickerController.text.trim();
      if (query.length < 2) {
        setState(() { _suggestions = []; _isLoadingSearch = false; });
        return;
      }
      if (_settingsProvider.isOnlineMode) {
        _search(query);
      } else {
        setState(() { _suggestions = []; _isLoadingSearch = false; });
      }
    });
  }

  // NOUVELLE FONCTION : Construit la liste des comptes groupés par institution
  List<DropdownMenuItem<Account>> _buildGroupedAccountItems() {
    final List<DropdownMenuItem<Account>> items = [];
    final portfolio = context.read<PortfolioProvider>().activePortfolio;
    if (portfolio == null) return items;

    final theme = Theme.of(context);
    // Style pour les en-têtes (Institutions)
    final headerStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    // Style pour les éléments (Comptes)
    final itemStyle = theme.textTheme.bodyLarge;

    for (final institution in portfolio.institutions) {
      // 1. En-tête de l'institution (non-sélectionnable)
      items.add(
        DropdownMenuItem<Account>(
          value: null,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              institution.name,
              style: headerStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      // 2. Comptes de l'institution
      for (final account in institution.accounts) {
        items.add(
          DropdownMenuItem<Account>(
            value: account,
            child: Padding(
              // Indentation pour la lisibilité
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                account.name,
                style: itemStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }

      // 3. Séparateur (optionnel)
      if (institution != portfolio.institutions.last) {
        items.add(
          const DropdownMenuItem<Account>(
            value: null,
            child: Divider(height: 4.0, thickness: 0.5),
          ),
        );
      }
    }
    return items;
  }

  Future<void> _search(String query) async {
    if (!_settingsProvider.isOnlineMode) return;
    setState(() { _isLoadingSearch = true; });
    final results = await _apiService.searchTicker(query);
    if (mounted) {
      setState(() { _suggestions = results; _isLoadingSearch = false; });
    }
  }

  void _onSuggestionSelected(TickerSuggestion suggestion) {
    _tickerController.removeListener(_onTickerChanged);
    _tickerController.text = suggestion.ticker;
    _nameController.text = suggestion.name;
    setState(() { _suggestions = []; });
    FocusScope.of(context).unfocus();
    if (_settingsProvider.isOnlineMode) {
      _apiService.getPrice(suggestion.ticker).then((price) {
        if (price != null && mounted) {
          _priceController.text = price.toStringAsFixed(2);
        }
      });
    }
    _tickerController.addListener(_onTickerChanged);
  }
  // --- FIN LOGIQUE DE RECHERCHE ---


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  /// --- LOGIQUE DE SOUMISSION (MODIFIÉE) ---
  void _submitForm() {
    if (!_formKey.currentState!.validate() || _selectedAccount == null) {
      // ... (gestion d'erreur identique) ...
      return;
    }

    final provider = context.read<PortfolioProvider>();

    // Parsing des valeurs (identique)
    final double amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final double? quantity =
    double.tryParse(_quantityController.text.replaceAll(',', '.'));
    final double? price =
    double.tryParse(_priceController.text.replaceAll(',', '.'));
    final double fees =
        double.tryParse(_feesController.text.replaceAll(',', '.')) ?? 0.0;

    // Logique de création (identique)
    double finalAmount = 0.0;
    String? assetTicker, assetName;

    switch (_selectedType) {
      case TransactionType.Deposit:
      case TransactionType.Interest:
        finalAmount = amount; // Positif
        break;
      case TransactionType.Withdrawal:
      case TransactionType.Fees:
        finalAmount = -amount; // Négatif
        break;
      case TransactionType.Dividend:
        finalAmount = amount; // Positif
        assetTicker = _tickerController.text.toUpperCase();
        assetName = _nameController.text;
        break;
      case TransactionType.Buy:
        finalAmount = -(quantity! * price!); // Négatif
        assetTicker = _tickerController.text.toUpperCase();
        assetName = _nameController.text;
        break;
      case TransactionType.Sell:
        finalAmount = (quantity! * price!); // Positif
        assetTicker = _tickerController.text.toUpperCase();
        assetName = _nameController.text;
        break;
    }

    // Attribue le type d'actif uniquement si c'est pertinent
    AssetType? finalAssetType;
    if (_selectedType == TransactionType.Buy ||
        _selectedType == TransactionType.Sell) {
      finalAssetType = _selectedAssetType;
    }
    // --- FIN AJOUT ---


    // --- MODIFICATION : Création de la transaction MISE À JOUR ---
    final updatedTransaction = Transaction(
      id: widget.existingTransaction.id, // <--- Garde l'ID existant
      accountId: _selectedAccount!.id,    // <--- Utilise le compte (potentiellement nouveau)
      type: _selectedType,
      date: _selectedDate,
      amount: finalAmount,
      fees: fees,
      assetTicker: assetTicker,
      assetName: assetName,
      quantity: quantity,
      price: price,
      notes: _notesController.text,
      assetType: finalAssetType,
    );

    // --- MODIFICATION : Appel de updateTransaction ---
    provider.updateTransaction(updatedTransaction);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre (MODIFIÉ)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modifier la Transaction', // <--- MODIFIÉ
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sélecteur de Compte
              DropdownButtonFormField<Account>(
                value: _selectedAccount,
                // --- MODIFICATIONS ---
                isExpanded: true, // Permet aux longs noms de s'afficher
                items: _buildGroupedAccountItems(),
                onChanged: (account) {
                  // On ignore les clics sur les en-têtes (qui ont une valeur null)
                  if (account != null) {
                    setState(() {
                      _selectedAccount = account;
                    });
                  }
                },
                // --- FIN MODIFICATIONS ---
                decoration: const InputDecoration(
                  labelText: 'Compte *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null ? 'Compte requis' : null,
              ),
              const SizedBox(height: 16),

              // Sélecteur de Type
              DropdownButtonFormField<TransactionType>(
                value: _selectedType,
                items: TransactionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (type) {
                  if (type != null) {
                    setState(() {
                      _suggestions = [];
                      _selectedType = type;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Type de transaction *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // --- CHAMPS DYNAMIQUES ---
              _buildDynamicFields(),

              // Champ Date
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Champ Frais
              TextFormField(
                controller: _feesController,
                decoration: const InputDecoration(
                  labelText: 'Frais',
                  border: OutlineInputBorder(),
                  suffixText: '€',
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis (0.0 si aucun)';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Nombre invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Champ Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optionnel)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Bouton Enregistrer
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'), // <--- MODIFIÉ
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit les champs de formulaire qui dépendent du type de transaction
  /// (Identique à AddTransactionScreen)
  Widget _buildDynamicFields() {
    switch (_selectedType) {
      case TransactionType.Deposit:
      case TransactionType.Withdrawal:
      case TransactionType.Interest:
      case TransactionType.Fees:
        return _buildCashFields();
      case TransactionType.Dividend:
        return _buildDividendFields();
      case TransactionType.Buy:
      case TransactionType.Sell:
        return _buildAssetFields();
    }
  }

  // Champs pour Dépôt, Retrait, Intérêts, Frais
  Widget _buildCashFields() {
    return Column(
      children: [
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Montant *',
            border: OutlineInputBorder(),
            suffixText: '€',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Montant requis';
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Nombre invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Champs pour Achat, Vente
  Widget _buildAssetFields() {
    return Column(
      children: [

        // --- NOUVEAU : Sélecteur de Type d'Actif ---
        DropdownButtonFormField<AssetType>(
          value: _selectedAssetType,
          items: AssetType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (type) {
            if (type != null) {
              setState(() {
                _selectedAssetType = type;
              });
            }
          },
          decoration: const InputDecoration(
            labelText: 'Type d\'actif *',
            border: OutlineInputBorder(),
          ),
        ),
        // --- FIN NOUVEAU ---
        const SizedBox(height: 16),

        TextFormField(
          controller: _tickerController,
          decoration: InputDecoration(
            labelText: 'Ticker (ex: AAPL) *',
            border: const OutlineInputBorder(),
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
          textCapitalization: TextCapitalization.characters,
          validator: (value) =>
          (value == null || value.isEmpty) ? 'Ticker requis' : null,
        ),
        if (_suggestions.isNotEmpty)
          SizedBox(
            height: 150,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
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
          ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom de l\'actif (ex: Apple Inc.) *',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
          (value == null || value.isEmpty) ? 'Nom requis' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité *',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,8}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire *',
                  border: OutlineInputBorder(),
                  suffixText: '€',
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Champs pour Dividende
  Widget _buildDividendFields() {
    return Column(
      children: [
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Montant reçu *',
            border: OutlineInputBorder(),
            suffixText: '€',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Montant requis';
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Nombre invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tickerController,
          decoration: const InputDecoration(
            labelText: 'Ticker (Optionnel)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom (ex: Dividende Apple)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}