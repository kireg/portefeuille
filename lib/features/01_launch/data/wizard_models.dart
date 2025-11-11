// lib/features/01_launch/data/wizard_models.dart
// Modèles temporaires pour l'assistant d'initialisation

import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

/// Représente une institution temporaire pendant le wizard
class WizardInstitution {
  String name;
  final List<WizardAccount> accounts;

  WizardInstitution({
    required this.name,
    List<WizardAccount>? accounts,
  }) : accounts = accounts ?? [];

  bool get isValid => name.trim().isNotEmpty;
}

/// Représente un compte temporaire pendant le wizard
class WizardAccount {
  String name;
  AccountType type;
  double cashBalance;
  final String institutionName; // Référence à l'institution parente
  final List<WizardAsset> assets;

  WizardAccount({
    required this.name,
    required this.type,
    required this.institutionName,
    this.cashBalance = 0.0,
    List<WizardAsset>? assets,
  }) : assets = assets ?? [];

  bool get isValid => name.trim().isNotEmpty && cashBalance >= 0;

  /// Identifiant unique pour le dropdown
  String get displayName => '$institutionName > $name';
}

/// Représente un actif temporaire pendant le wizard
class WizardAsset {
  String ticker;
  String name;
  AssetType? type;
  double quantity;
  double averagePrice; // PRU
  double currentPrice; // Prix actuel (pour calculer la valeur actuelle)
  double? estimatedYield; // Rendement annuel estimé (optionnel, en %)
  DateTime firstPurchaseDate;
  final String accountDisplayName; // Référence au compte parent

  WizardAsset({
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.firstPurchaseDate,
    required this.accountDisplayName,
    this.type,
    this.estimatedYield,
  });

  bool get isValid =>
      ticker.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      quantity > 0 &&
      averagePrice > 0 &&
      currentPrice > 0;

  /// Valeur totale de la position (quantité × prix actuel)
  double get totalValue => quantity * currentPrice;
}
