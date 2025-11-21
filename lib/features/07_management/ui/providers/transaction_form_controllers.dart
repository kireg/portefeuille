// lib/features/07_management/ui/providers/transaction_form_controllers.dart

import 'package:flutter/material.dart';

/// Ce mixin gère l'initialisation et le nettoyage de tous les contrôleurs de texte.
mixin TransactionFormControllers {
  final formKey = GlobalKey<FormState>();

  // Contrôleurs
  late final TextEditingController amountController;
  late final TextEditingController tickerController;
  late final TextEditingController nameController;
  late final TextEditingController quantityController;
  late final TextEditingController priceController;
  late final TextEditingController feesController;
  late final TextEditingController notesController;
  late final TextEditingController dateController;
  late final TextEditingController priceCurrencyController;
  late final TextEditingController exchangeRateController;

  void initControllers() {
    amountController = TextEditingController();
    tickerController = TextEditingController();
    nameController = TextEditingController();
    quantityController = TextEditingController();
    priceController = TextEditingController();
    feesController = TextEditingController();
    notesController = TextEditingController();
    dateController = TextEditingController();
    priceCurrencyController = TextEditingController();
    exchangeRateController = TextEditingController();
  }

  void disposeControllers() {
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
  }

  /// Vide les champs pour une nouvelle saisie (utile pour le mode Batch)
  void clearFieldsForNextTransaction() {
    amountController.clear();
    tickerController.clear();
    nameController.clear();
    quantityController.clear();
    priceController.clear();
    feesController.text = '0.0';
    notesController.clear();
    // On ne clear pas la date, la devise ou le taux par confort
  }
}