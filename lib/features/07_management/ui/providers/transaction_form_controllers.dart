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

  // --- CROWDFUNDING ---
  late final TextEditingController platformController;
  late final TextEditingController locationController;
  late final TextEditingController minDurationController;
  late final TextEditingController targetDurationController;
  late final TextEditingController maxDurationController;
  late final TextEditingController expectedYieldController;
  late final TextEditingController riskRatingController;
  // --- FIN CROWDFUNDING ---

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

    // --- CROWDFUNDING ---
    platformController = TextEditingController();
    locationController = TextEditingController();
    minDurationController = TextEditingController();
    targetDurationController = TextEditingController();
    maxDurationController = TextEditingController();
    expectedYieldController = TextEditingController();
    riskRatingController = TextEditingController();
    // --- FIN CROWDFUNDING ---
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

    // --- CROWDFUNDING ---
    platformController.dispose();
    locationController.dispose();
    minDurationController.dispose();
    targetDurationController.dispose();
    maxDurationController.dispose();
    expectedYieldController.dispose();
    riskRatingController.dispose();
    // --- FIN CROWDFUNDING ---
  }

  /// Vide les champs pour une nouvelle saisie (utile pour le mode Batch)
  void clearFieldsForNextTransaction() {
    amountController.clear();
    tickerController.clear();
    // ... (existing clear calls)
    // Note: Crowdfunding fields might not need clearing if we are in batch mode for same asset?
    // But usually batch is for different assets.
    // Let's clear them too.
    platformController.clear();
    locationController.clear();
    minDurationController.clear();
    targetDurationController.clear();
    maxDurationController.clear();
    expectedYieldController.clear();
    riskRatingController.clear();

    nameController.clear();
    quantityController.clear();
    priceController.clear();
    feesController.text = '0.0';
    notesController.clear();
    // On ne clear pas la date, la devise ou le taux par confort
  }
}