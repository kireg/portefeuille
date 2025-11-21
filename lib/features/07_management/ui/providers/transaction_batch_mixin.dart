// lib/features/07_management/ui/providers/transaction_batch_mixin.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/transaction_extraction_result.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_controllers.dart';

/// Ce mixin gère la file d'attente des transactions importées par IA.
mixin TransactionBatchMixin on ChangeNotifier, TransactionFormControllers {

  // Dépendances
  SettingsProvider get settingsProvider;

  // Méthodes abstraites renommées pour matcher l'UI
  void selectType(TransactionType type);
  void selectAssetType(AssetType type);
  void setDate(DateTime date); // Distingué de selectDate(context)

  void triggerSearch(String ticker);

  // État de la file d'attente
  List<TransactionExtractionResult> _pendingExtractions = [];
  int _totalBatchCount = 0;

  bool get hasPendingTransactions => _pendingExtractions.isNotEmpty;
  int get remainingTransactions => _pendingExtractions.length;

  void applyExtractionResults(List<TransactionExtractionResult> results) {
    if (results.isEmpty) return;

    _pendingExtractions = List.from(results);
    _totalBatchCount = results.length;

    loadNextPending();
  }

  void loadNextPending() {
    if (_pendingExtractions.isEmpty) return;

    final result = _pendingExtractions.removeAt(0);
    _applySingleResult(result);

    notifyListeners();
  }

  void _applySingleResult(TransactionExtractionResult result) {
    if (result.amount != null) amountController.text = result.amount!.toStringAsFixed(2);
    if (result.quantity != null) quantityController.text = result.quantity!.toString();
    if (result.price != null) priceController.text = result.price!.toStringAsFixed(2);
    if (result.fees != null) feesController.text = result.fees!.toStringAsFixed(2);
    if (result.name != null) nameController.text = result.name!;
    if (result.currency != null) priceCurrencyController.text = result.currency!;

    if (result.date != null) {
      setDate(result.date!); // Appel interne
      dateController.text = DateFormat('dd/MM/yyyy').format(result.date!);
    }

    if (result.type != null) {
      selectType(result.type!); // Correspond maintenant à la méthode UI
    }

    if (result.assetType != null) {
      selectAssetType(result.assetType!); // Correspond maintenant à la méthode UI
    }

    if (result.ticker != null) {
      tickerController.text = result.ticker!;
      if (settingsProvider.isOnlineMode) {
        triggerSearch(result.ticker!);
      }
    }
  }
}