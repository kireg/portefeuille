// lib/features/07_management/ui/providers/transaction_search_mixin.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_controllers.dart';

/// Ce mixin gère la recherche de Ticker et la récupération des prix.
mixin TransactionSearchMixin on ChangeNotifier, TransactionFormControllers {

  // Dépendances requises
  ApiService get apiService;
  SettingsProvider get settingsProvider;
  String get accountCurrency;

  // État local de la recherche
  Timer? _debounce;
  List<TickerSuggestion> _suggestions = [];
  bool _isLoadingSearch = false;

  List<TickerSuggestion> get suggestions => _suggestions;
  bool get isLoadingSearch => _isLoadingSearch;

  void onTickerChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = tickerController.text.trim();
      if (query.length < 2) {
        _suggestions = [];
        _isLoadingSearch = false;
        notifyListeners();
        return;
      }
      if (settingsProvider.isOnlineMode) {
        _search(query);
      } else {
        _suggestions = [];
        _isLoadingSearch = false;
        notifyListeners();
      }
    });
  }

  Future<void> _search(String query) async {
    if (!settingsProvider.isOnlineMode) return;
    _isLoadingSearch = true;
    notifyListeners();

    try {
      final results = await apiService.searchTicker(query);
      _suggestions = results;
    } catch (e) {
      _suggestions = [];
    } finally {
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  // Correction : Suppression du callback inutile, utilisation directe de notifyListeners()
  void onSuggestionSelected(TickerSuggestion suggestion, BuildContext context) async {
    tickerController.text = suggestion.ticker;
    nameController.text = suggestion.name;
    priceCurrencyController.text = suggestion.currency.toUpperCase();

    _suggestions = [];
    notifyListeners();

    if (!context.mounted) return;
    FocusScope.of(context).unfocus();

    if (settingsProvider.isOnlineMode) {
      try {
        final priceResult = await apiService.getPrice(suggestion.ticker);
        if (priceResult.price != null) {
          priceController.text = priceResult.price!.toStringAsFixed(2);
          priceCurrencyController.text = priceResult.currency;
        }

        if (priceResult.currency != accountCurrency) {
          final rate = await apiService.getExchangeRate(priceResult.currency, accountCurrency);
          exchangeRateController.text = rate.toStringAsFixed(4);
        } else {
          exchangeRateController.text = "1.0";
        }
      } catch (e) {
        // Log erreur
      }
      notifyListeners();
    }
  }

  void cancelDebounce() {
    _debounce?.cancel();
  }
}