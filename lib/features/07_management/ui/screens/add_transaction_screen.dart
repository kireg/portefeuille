// lib/features/07_management/ui/screens/add_transaction_screen.dart
// REMPLACEZ LE FICHIER COMPLET

import 'dart:async'; // <--- NOUVEL IMPORT
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

// --- NOUVEAUX IMPORTS ---
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
// --- FIN NOUVEAUX IMPORTS ---

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // État du formulaire
  Account? _selectedAccount;
  TransactionType _selectedType = TransactionType.Deposit;
  DateTime _selectedDate = DateTime.now();
  AssetType _selectedAssetType = AssetType.Stock;

  // Contrôleurs
  final _amountController = TextEditingController();
  final _tickerController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _feesController = TextEditingController(text: '0.0');
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  // Liste des comptes disponibles
  List<Account> _availableAccounts = [];

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
    // Charger les comptes
    final portfolio = context.read<PortfolioProvider>().activePortfolio;
    if (portfolio != null) {
      _availableAccounts =
          portfolio.institutions.expand((inst) => inst.accounts).toList();
      if (_availableAccounts.isNotEmpty) {
        _selectedAccount = _availableAccounts.first;
      }
    }
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);

    // --- NOUVEAU : Initialisation des services et listener ---
    _apiService = context.read<ApiService>();
    _settingsProvider = context.read<SettingsProvider>();
    _tickerController.addListener(_onTickerChanged);
    // --- FIN NOUVEAU ---
  }

  @override
  void dispose() {
    // ... (dispose des autres contrôleurs) ...
    _amountController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _feesController.dispose();
    _notesController.dispose();
    _dateController.dispose();

    // --- NOUVEAU : Nettoyage du listener et debounce ---
    _tickerController.removeListener(_onTickerChanged);
    _tickerController.dispose();
    _debounce?.cancel();
    // --- FIN NOUVEAU ---
    super.dispose();
  }

  // --- NOUVELLES MÉTHODES (logique de recherche) ---

  void _onTickerChanged() {
    // Ne pas rechercher si ce n'est pas un achat/vente
    if (_selectedType != TransactionType.Buy &&
        _selectedType != TransactionType.Sell) {
      return;
    }

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

      if (_settingsProvider.isOnlineMode) {
        _search(query);
      } else {
        setState(() {
          _suggestions = [];
          _isLoadingSearch = false;
        });
      }
    });
  }

  Future<void> _search(String query) async {
    if (!_settingsProvider.isOnlineMode) return;

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

  /// Lorsqu'un utilisateur clique sur une suggestion
  void _onSuggestionSelected(TickerSuggestion suggestion) {
    // Retirer temporairement le listener
    _tickerController.removeListener(_onTickerChanged);

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
          _priceController.text = price.toStringAsFixed(2);
        }
      });
    }

    // 4. Rattacher le listener
    _tickerController.addListener(_onTickerChanged);
  }
  // --- FIN NOUVELLES MÉTHODES ---

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

  void _submitForm() {
    if (!_formKey.currentState!.validate() || _selectedAccount == null) {
      if (_selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un compte.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final provider = context.read<PortfolioProvider>();

    // Parsing des valeurs
    final double amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final double? quantity =
    double.tryParse(_quantityController.text.replaceAll(',', '.'));
    final double? price =
    double.tryParse(_priceController.text.replaceAll(',', '.'));
    final double fees =
        double.tryParse(_feesController.text.replaceAll(',', '.')) ?? 0.0;

    // Logique de création de la transaction
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

    final newTransaction = Transaction(
      id: _uuid.v4(),
      accountId: _selectedAccount!.id,
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

    provider.addTransaction(newTransaction);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method)
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
              // Titre
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nouvelle Transaction',
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
                      // Vider les suggestions si on change de type
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
                label: const Text('Enregistrer'),
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
        const SizedBox(height: 16), // <--- AJOUTÉ

        TextFormField(
          controller: _tickerController,
          decoration: InputDecoration(
            labelText: 'Ticker (ex: AAPL) *',
            border: const OutlineInputBorder(),
            // --- NOUVELLE LOGIQUE D'ICÔNE ---
            suffixIcon: _isLoadingSearch && _settingsProvider.isOnlineMode
                ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
                : null,
            // --- FIN NOUVELLE LOGIQUE ---
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) =>
          (value == null || value.isEmpty) ? 'Ticker requis' : null,
        ),
        // --- NOUVEAU : AFFICHAGE DES SUGGESTIONS ---
        if (_suggestions.isNotEmpty)
          SizedBox(
            height: 150, // Hauteur fixe
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
        // --- FIN NOUVEAU ---
        const SizedBox(height: 12), // Espaceur
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