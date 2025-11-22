// lib/features/07_management/ui/providers/transaction_form_state.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/repayment_type.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/core/data/services/geocoding_service.dart';
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
  RepaymentType? _selectedRepaymentType;
  List<Account> _availableAccounts = [];

  bool get isEditing => existingTransaction != null;
  Account? get selectedAccount => _selectedAccount;
  TransactionType get selectedType => _selectedType;
  DateTime get selectedDate => _selectedDate;
  AssetType get selectedAssetType => _selectedAssetType;
  RepaymentType? get selectedRepaymentType => _selectedRepaymentType;
  List<Account> get availableAccounts => _availableAccounts;

  String? _locationError;
  String? get locationError => _locationError;

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
    
    // Clear location error on typing
    locationController.addListener(() {
      if (_locationError != null) {
        _locationError = null;
        notifyListeners();
      }
    });
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

      // --- CROWDFUNDING ---
      if (tx.assetType == AssetType.RealEstateCrowdfunding && tx.assetTicker != null) {
        final metadata = _portfolioProvider.allMetadata[tx.assetTicker];
        if (metadata != null) {
          locationController.text = metadata.location ?? '';
          minDurationController.text = metadata.minDuration?.toString() ?? '';
          targetDurationController.text = metadata.targetDuration?.toString() ?? '';
          maxDurationController.text = metadata.maxDuration?.toString() ?? '';
          expectedYieldController.text = metadata.expectedYield?.toString() ?? '';
          riskRatingController.text = metadata.riskRating ?? '';
          _selectedRepaymentType = metadata.repaymentType;
        }
      }
      // --- FIN CROWDFUNDING ---
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

  void setRepaymentType(RepaymentType? type) {
    _selectedRepaymentType = type;
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

  Future<void> submitForm(BuildContext context) async {
    if (!formKey.currentState!.validate() || _selectedAccount == null) {
      if (_selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un compte.'),
            backgroundColor: Colors.red,
            showCloseIcon: true,
          ),
        );
      }
      return;
    }

    final double amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
    final double? quantity = double.tryParse(quantityController.text.replaceAll(',', '.'));
    
    // Pour le Crowdfunding, le prix est implicitement 1.0 si non renseigné
    double? price = double.tryParse(priceController.text.replaceAll(',', '.'));
    if (_selectedAssetType == AssetType.RealEstateCrowdfunding && price == null) {
      price = 1.0;
    }

    final double fees = double.tryParse(feesController.text.replaceAll(',', '.')) ?? 0.0;
    final String? priceCurrency = priceCurrencyController.text.trim().isEmpty
        ? null
        : priceCurrencyController.text.trim().toUpperCase();
    final double? exchangeRate = double.tryParse(exchangeRateController.text.replaceAll(',', '.'));

    double finalAmount = 0.0;
    String? assetTicker, assetName;

    // Helper pour générer un ticker si absent (Crowdfunding)
    String getOrGenerateTicker() {
      String t = tickerController.text.trim().toUpperCase();
      if (t.isEmpty && _selectedAssetType == AssetType.RealEstateCrowdfunding) {
        // Génère un ticker basé sur le nom (ex: "RESIDENCE LES PINS" -> "RESIDENCELESPINS")
        t = nameController.text.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
        if (t.isEmpty) t = "CROWD_${DateTime.now().millisecondsSinceEpoch}";
      }
      return t;
    }

    switch (_selectedType) {
      case TransactionType.Deposit:
      case TransactionType.Interest:
        finalAmount = amount;
        if (tickerController.text.isNotEmpty || nameController.text.isNotEmpty) {
           assetTicker = getOrGenerateTicker();
           assetName = nameController.text;
        }
        break;
      case TransactionType.Withdrawal:
      case TransactionType.Fees:
        finalAmount = -amount;
        break;
      case TransactionType.Dividend:
        finalAmount = amount;
        assetTicker = getOrGenerateTicker();
        assetName = nameController.text;
        break;
      case TransactionType.Buy:
        // Validation spécifique
        if (quantity == null || price == null) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quantité ou Prix manquant.'),
              backgroundColor: Colors.red,
              showCloseIcon: true,
            ),
          );
          return;
        }
        finalAmount = -(quantity * price * (exchangeRate ?? 1.0));
        assetTicker = getOrGenerateTicker();
        assetName = nameController.text;
        break;
      case TransactionType.Sell:
      case TransactionType.CapitalRepayment:
      case TransactionType.EarlyRepayment:
         if (quantity == null || price == null) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quantité ou Prix manquant.'),
              backgroundColor: Colors.red,
              showCloseIcon: true,
            ),
          );
          return;
        }
        finalAmount = (quantity * price * (exchangeRate ?? 1.0));
        assetTicker = getOrGenerateTicker();
        assetName = nameController.text;
        break;
    }

    // --- VALIDATION CROWDFUNDING (GEOLOCALISATION) ---
    if ((_selectedType == TransactionType.Buy || _selectedType == TransactionType.Sell) && 
        _selectedAssetType == AssetType.RealEstateCrowdfunding && 
        locationController.text.trim().isNotEmpty) {
        
        final location = locationController.text.trim();
        debugPrint("🔍 [TransactionForm] Validation de la localisation Crowdfunding : $location");
        
        final geocodingService = GeocodingService();
        final coords = await geocodingService.getCoordinates(location);
        
        if (coords == null) {
            debugPrint("❌ [TransactionForm] Localisation invalide : $location");
            _locationError = "Ville introuvable. Vérifiez l'orthographe.";
            notifyListeners();
            
            if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("La ville '$location' est introuvable."),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                    ),
                );
            }
            return; // Bloquer la soumission
        } else {
            debugPrint("✅ [TransactionForm] Localisation valide : $location (${coords['lat']}, ${coords['lon']})");
            _locationError = null; // Clear error if valid
        }
    }
    // --- FIN VALIDATION ---

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

    // --- CROWDFUNDING METADATA ---
    if (finalAssetType == AssetType.RealEstateCrowdfunding && assetTicker != null) {
       // Fetch existing or create new
       var metadata = _portfolioProvider.allMetadata[assetTicker] ?? AssetMetadata(ticker: assetTicker);
       
       // Geocoding automatique si la localisation est renseignée
       final location = locationController.text.trim();
       double? lat, lon;
       
       if (location.isNotEmpty) {
         // On ne refait le géocodage que si la localisation a changé ou si les coordonnées sont manquantes
         if (metadata.location != location || metadata.latitude == null) {
            final geocodingService = GeocodingService();
            final coords = await geocodingService.getCoordinates(location);
            if (coords != null) {
              lat = coords['lat'];
              lon = coords['lon'];
            }
         } else {
            // Conserver les anciennes coordonnées si la ville n'a pas changé
            lat = metadata.latitude;
            lon = metadata.longitude;
         }
       }

       // Update fields
       metadata = metadata.copyWith(
         // platform: platformController.text.trim().isEmpty ? null : platformController.text.trim(), // SUPPRIMÉ
         location: location.isEmpty ? null : location,
         minDuration: int.tryParse(minDurationController.text),
         targetDuration: int.tryParse(targetDurationController.text),
         maxDuration: int.tryParse(maxDurationController.text),
         expectedYield: double.tryParse(expectedYieldController.text.replaceAll(',', '.')),
         riskRating: riskRatingController.text.trim().isEmpty ? null : riskRatingController.text.trim(),
         repaymentType: _selectedRepaymentType,
         assetTypeDetailed: 'RealEstateCrowdfunding',
         latitude: lat,
         longitude: lon,
       );
       
       _portfolioProvider.updateAssetMetadata(metadata);
    }
    // --- FIN CROWDFUNDING METADATA ---

    if (hasPendingTransactions) {
      final remaining = remainingTransactions;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enregistré ! Reste $remaining transaction(s)...'),
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 2),
            showCloseIcon: true,
          ),
        );
      }

      clearFieldsForNextTransaction();
      loadNextPending();

    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction enregistrée.'),
            backgroundColor: Colors.green,
            showCloseIcon: true,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}