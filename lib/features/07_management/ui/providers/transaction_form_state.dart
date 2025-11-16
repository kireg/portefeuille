// lib/features/07_management/ui/providers/transaction_form_state.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

class TransactionFormState extends ChangeNotifier {
  // Dépendances
  final ApiService _apiService;
  final SettingsProvider _settingsProvider;
  final PortfolioProvider _portfolioProvider;
  final Transaction? existingTransaction;

  // Clés et UUID
  final formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // État du formulaire
  Account? _selectedAccount;
  TransactionType _selectedType;
  DateTime _selectedDate;
  AssetType _selectedAssetType;

  // Contrôleurs
  final amountController = TextEditingController();
  final tickerController = TextEditingController();
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  final feesController = TextEditingController();
  final notesController = TextEditingController();
  final dateController = TextEditingController();
  final priceCurrencyController = TextEditingController();
  final exchangeRateController = TextEditingController();

  List<Account> _availableAccounts = [];

  // Logique de recherche
  Timer? _debounce;
  List<TickerSuggestion> _suggestions = [];
  bool _isLoadingSearch = false;

  // Getters
  bool get isEditing => existingTransaction != null;
  Account? get selectedAccount => _selectedAccount;
  TransactionType get selectedType => _selectedType;
  DateTime get selectedDate => _selectedDate;
  AssetType get selectedAssetType => _selectedAssetType;
  List<Account> get availableAccounts => _availableAccounts;
  List<TickerSuggestion> get suggestions => _suggestions;
  bool get isLoadingSearch => _isLoadingSearch;
  SettingsProvider get settingsProvider => _settingsProvider;

  // Getter pour la devise du compte (avec fallback)
  String get accountCurrency {
    return _selectedAccount?.currency ?? _settingsProvider.baseCurrency;
  }

  TransactionFormState({
    required this.existingTransaction,
    required ApiService apiService,
    required SettingsProvider settingsProvider,
    required PortfolioProvider portfolioProvider,
  })  : _apiService = apiService,
        _settingsProvider = settingsProvider,
        _portfolioProvider = portfolioProvider,
        // Initialisation des valeurs par défaut
        _selectedType = existingTransaction?.type ?? TransactionType.Deposit,
        _selectedDate = existingTransaction?.date ?? DateTime.now(),
        _selectedAssetType = existingTransaction?.assetType ?? AssetType.Stock {
    // --- CHARGEMENT DES COMPTES ---
    final portfolio = _portfolioProvider.activePortfolio;
    if (portfolio != null) {
      _availableAccounts =
          portfolio.institutions.expand((inst) => inst.accounts).toList();
    }

    // --- PRÉ-REMPLISSAGE ---
    final tx = existingTransaction;
    if (tx != null) {
      try {
        _selectedAccount = _availableAccounts.firstWhere(
          (acc) => acc.id == tx.accountId,
        );
      } catch (e) {
        _selectedAccount =
            _availableAccounts.isNotEmpty ? _availableAccounts.first : null;
      }
    } else {
      _selectedAccount =
          _availableAccounts.isNotEmpty ? _availableAccounts.first : null;
    }

    dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    notesController.text = tx?.notes ?? '';
    feesController.text = tx?.fees.toStringAsFixed(2) ?? '0.0';
    tickerController.text = tx?.assetTicker ?? '';
    nameController.text = tx?.assetName ?? '';
    quantityController.text = tx?.quantity?.toString() ?? '';
    priceController.text = tx?.price?.toString() ?? '';
    amountController.text = tx?.amount.abs().toStringAsFixed(2) ?? '';

    priceCurrencyController.text = tx?.priceCurrency ?? accountCurrency;
    exchangeRateController.text = tx?.exchangeRate?.toString() ?? '1.0';

    tickerController.addListener(_onTickerChanged);
  }

  @override
  void dispose() {
    amountController.dispose();
    tickerController.dispose();
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    feesController.dispose();
    notesController.dispose();
    dateController.dispose();
    priceCurrencyController.dispose();
    exchangeRateController.dispose();
    tickerController.removeListener(_onTickerChanged);
    _debounce?.cancel();
    super.dispose();
  }

  // --- LOGIQUE MÉTIER ---

  void _onTickerChanged() {
    if (_selectedType != TransactionType.Buy &&
        _selectedType != TransactionType.Sell) {
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = tickerController.text.trim();
      if (query.length < 2) {
        _suggestions = [];
        _isLoadingSearch = false;
        notifyListeners();
        return;
      }
      if (_settingsProvider.isOnlineMode) {
        _search(query);
      } else {
        _suggestions = [];
        _isLoadingSearch = false;
        notifyListeners();
      }
    });
  }

  Future<void> _search(String query) async {
    if (!_settingsProvider.isOnlineMode) return;
    _isLoadingSearch = true;
    notifyListeners();

    final results = await _apiService.searchTicker(query);
    _suggestions = results;
    _isLoadingSearch = false;
    notifyListeners();
  }

  void onSuggestionSelected(
      TickerSuggestion suggestion, BuildContext context) async {
    tickerController.removeListener(_onTickerChanged);
    tickerController.text = suggestion.ticker;
    nameController.text = suggestion.name;

    final priceCurrency = suggestion.currency.toUpperCase();
    priceCurrencyController.text = priceCurrency;

    _suggestions = [];
    notifyListeners();

    // Vérifier que le widget est toujours monté avant d'utiliser le context
    if (!context.mounted) return;
    FocusScope.of(context).unfocus();

    if (_settingsProvider.isOnlineMode) {
      final priceResult = await _apiService.getPrice(suggestion.ticker);
      if (priceResult.price != null) {
        priceController.text = priceResult.price!.toStringAsFixed(2);
        priceCurrencyController.text = priceResult.currency;
      }

      if (priceResult.currency != accountCurrency) {
        final rate = await _apiService.getExchangeRate(
            priceResult.currency, accountCurrency);
        exchangeRateController.text = rate.toStringAsFixed(4);
      } else {
        exchangeRateController.text = "1.0";
      }
    }
    tickerController.addListener(_onTickerChanged);
    notifyListeners();
  }

  List<DropdownMenuItem<Account>> buildGroupedAccountItems(
      BuildContext context) {
    final List<DropdownMenuItem<Account>> items = [];
    final portfolio = _portfolioProvider.activePortfolio;
    if (portfolio == null) return items;

    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    final itemStyle = theme.textTheme.bodyLarge;
    for (final institution in portfolio.institutions) {
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
      for (final account in institution.accounts) {
        items.add(
          DropdownMenuItem<Account>(
            value: account,
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                '${account.name} (${account.currency})',
                style: itemStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
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

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      notifyListeners();
    }
  }

  void selectAccount(Account? account) {
    if (account != null) {
      _selectedAccount = account;
      // Si on change de compte, on réinitialise le taux de change
      // et la devise du prix par défaut
      priceCurrencyController.text = account.activeCurrency;
      exchangeRateController.text = "1.0";
      notifyListeners();
    }
  }

  void selectType(TransactionType? type) {
    if (type != null) {
      _suggestions = [];
      _selectedType = type;
      notifyListeners();
    }
  }

  void selectAssetType(AssetType? type) {
    if (type != null) {
      _selectedAssetType = type;
      notifyListeners();
    }
  }

  void submitForm(BuildContext context) {
    if (!formKey.currentState!.validate() || _selectedAccount == null) {
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

    final double amount =
        double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
    final double? quantity =
        double.tryParse(quantityController.text.replaceAll(',', '.'));
    final double? price =
        double.tryParse(priceController.text.replaceAll(',', '.'));
    final double fees =
        double.tryParse(feesController.text.replaceAll(',', '.')) ?? 0.0;
    final String? priceCurrency = priceCurrencyController.text.trim().isEmpty
        ? null
        : priceCurrencyController.text.trim().toUpperCase();
    final double? exchangeRate =
        double.tryParse(exchangeRateController.text.replaceAll(',', '.'));

    double finalAmount = 0.0;
    String? assetTicker, assetName;

    switch (_selectedType) {
      case TransactionType.Deposit:
      case TransactionType.Interest:
        finalAmount = amount;
        break;
      case TransactionType.Withdrawal:
      case TransactionType.Fees:
        finalAmount = -amount;
        break;
      case TransactionType.Dividend:
        finalAmount = amount;
        assetTicker = tickerController.text.toUpperCase();
        assetName = nameController.text;
        break;
      case TransactionType.Buy:
        finalAmount = -(quantity! * price! * (exchangeRate ?? 1.0));
        assetTicker = tickerController.text.toUpperCase();
        assetName = nameController.text;
        break;
      case TransactionType.Sell:
        finalAmount = (quantity! * price! * (exchangeRate ?? 1.0));
        assetTicker = tickerController.text.toUpperCase();
        assetName = nameController.text;
        break;
    }

    AssetType? finalAssetType;
    if (_selectedType == TransactionType.Buy ||
        _selectedType == TransactionType.Sell) {
      finalAssetType = _selectedAssetType;
    }

    final String transactionId =
        isEditing ? existingTransaction!.id : _uuid.v4();

    final transaction = Transaction(
      id: transactionId,
      accountId: _selectedAccount!.id,
      type: _selectedType,
      date: _selectedDate,
      amount: finalAmount,
      fees: fees,
      assetTicker: assetTicker,
      assetName: assetName,
      quantity: quantity,
      price: price,
      notes: notesController.text,
      assetType: finalAssetType,
      priceCurrency: priceCurrency,
      exchangeRate: exchangeRate,
    );

    if (isEditing) {
      _portfolioProvider.updateTransaction(transaction);
    } else {
      _portfolioProvider.addTransaction(transaction);
    }

    // Vérifier que le widget est toujours monté avant de fermer
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}
