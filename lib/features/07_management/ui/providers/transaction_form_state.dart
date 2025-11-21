// lib/features/07_management/ui/providers/transaction_form_state.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

import 'transaction_form_controllers.dart';
import 'transaction_search_mixin.dart';
import 'transaction_batch_mixin.dart';

class TransactionFormState extends ChangeNotifier
    with TransactionFormControllers, TransactionSearchMixin, TransactionBatchMixin {

  @override
  final ApiService apiService;
  @override
  final SettingsProvider settingsProvider;
  final PortfolioProvider _portfolioProvider;
  final Transaction? existingTransaction;

  final _uuid = const Uuid();

  Account? _selectedAccount;
  TransactionType _selectedType;
  DateTime _selectedDate;
  AssetType _selectedAssetType;
  List<Account> _availableAccounts = [];

  bool get isEditing => existingTransaction != null;
  Account? get selectedAccount => _selectedAccount;
  TransactionType get selectedType => _selectedType;
  DateTime get selectedDate => _selectedDate;
  AssetType get selectedAssetType => _selectedAssetType;
  List<Account> get availableAccounts => _availableAccounts;

  @override
  String get accountCurrency {
    return _selectedAccount?.currency ?? settingsProvider.baseCurrency;
  }

  TransactionFormState({
    required this.existingTransaction,
    required this.apiService,
    required this.settingsProvider,
    required PortfolioProvider portfolioProvider,
  })  : _portfolioProvider = portfolioProvider,
        _selectedType = existingTransaction?.type ?? TransactionType.Deposit,
        _selectedDate = existingTransaction?.date ?? DateTime.now(),
        _selectedAssetType = existingTransaction?.assetType ?? AssetType.Stock {

    initControllers();

    final portfolio = _portfolioProvider.activePortfolio;
    if (portfolio != null) {
      _availableAccounts = portfolio.institutions.expand((inst) => inst.accounts).toList();
    }

    _initializeValues();

    // Correction : Appel sans paramètre (géré par le mixin)
    tickerController.addListener(onTickerChanged);
  }

  void _initializeValues() {
    final tx = existingTransaction;

    if (tx != null) {
      try {
        _selectedAccount = _availableAccounts.firstWhere((acc) => acc.id == tx.accountId);
      } catch (e) {
        _selectedAccount = _availableAccounts.isNotEmpty ? _availableAccounts.first : null;
      }
    } else {
      _selectedAccount = _availableAccounts.isNotEmpty ? _availableAccounts.first : null;
    }

    dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);

    if (tx != null) {
      notesController.text = tx.notes;
      feesController.text = tx.fees.toStringAsFixed(2);
      tickerController.text = tx.assetTicker ?? '';
      nameController.text = tx.assetName ?? '';
      quantityController.text = tx.quantity?.toString() ?? '';
      priceController.text = tx.price?.toString() ?? '';
      amountController.text = tx.amount.abs().toStringAsFixed(2);
      priceCurrencyController.text = tx.priceCurrency ?? accountCurrency;
      exchangeRateController.text = tx.exchangeRate?.toString() ?? '1.0';
    } else {
      feesController.text = '0.0';
      exchangeRateController.text = '1.0';
      priceCurrencyController.text = accountCurrency;
    }
  }

  @override
  void dispose() {
    tickerController.removeListener(onTickerChanged);
    cancelDebounce();
    disposeControllers();
    super.dispose();
  }

  // --- IMPLEMENTATION INTERFACE MIXIN & UI ---

  // Utilisé par l'UI (Dropdown) ET le BatchMixin
  @override
  void selectType(TransactionType? type) {
    if (type != null) {
      _selectedType = type;
      notifyListeners();
    }
  }

  // Utilisé par l'UI (Dropdown) ET le BatchMixin
  @override
  void selectAssetType(AssetType? type) {
    if (type != null) {
      _selectedAssetType = type;
      notifyListeners();
    }
  }

  // Utilisé par le BatchMixin (interne)
  @override
  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  @override
  void triggerSearch(String ticker) {
    onTickerChanged(); // Plus besoin de paramètre
  }

  // --- MÉTHODES UI ---

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
      priceCurrencyController.text = account.activeCurrency;
      exchangeRateController.text = "1.0";
      notifyListeners();
    }
  }

  List<DropdownMenuItem<Account>> buildGroupedAccountItems(BuildContext context) {
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
      items.add(DropdownMenuItem<Account>(
        value: null,
        enabled: false,
        child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(institution.name, style: headerStyle, overflow: TextOverflow.ellipsis)),
      ));
      for (final account in institution.accounts) {
        items.add(DropdownMenuItem<Account>(
          value: account,
          child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text('${account.name} (${account.currency})', style: itemStyle, overflow: TextOverflow.ellipsis)),
        ));
      }
      if (institution != portfolio.institutions.last) {
        items.add(const DropdownMenuItem<Account>(value: null, enabled: false, child: Divider(height: 4.0, thickness: 0.5)));
      }
    }
    return items;
  }

  void submitForm(BuildContext context) {
    if (!formKey.currentState!.validate() || _selectedAccount == null) {
      if (_selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un compte.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final double amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
    final double? quantity = double.tryParse(quantityController.text.replaceAll(',', '.'));
    final double? price = double.tryParse(priceController.text.replaceAll(',', '.'));
    final double fees = double.tryParse(feesController.text.replaceAll(',', '.')) ?? 0.0;
    final String? priceCurrency = priceCurrencyController.text.trim().isEmpty
        ? null
        : priceCurrencyController.text.trim().toUpperCase();
    final double? exchangeRate = double.tryParse(exchangeRateController.text.replaceAll(',', '.'));

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
    if (_selectedType == TransactionType.Buy || _selectedType == TransactionType.Sell) {
      finalAssetType = _selectedAssetType;
    }

    final transaction = Transaction(
      id: isEditing ? existingTransaction!.id : _uuid.v4(),
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

    if (hasPendingTransactions) {
      final remaining = remainingTransactions;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enregistré ! Reste $remaining transaction(s)...'),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 2),
        ),
      );

      clearFieldsForNextTransaction();
      loadNextPending();

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction enregistrée.'), backgroundColor: Colors.green),
      );
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}