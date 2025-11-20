// lib/features/01_launch/data/wizard_models.dart
// Modèles temporaires pour l'assistant d'initialisation

import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

/// Représente un compte temporaire pendant le wizard
class WizardAccount {
  final String id;
  String name;
  AccountType type;
  double cashBalance;
  String institutionName;
  final List<WizardAsset> assets;

  WizardAccount({
    String? id,
    required this.name,
    required this.type,
    required this.institutionName,
    this.cashBalance = 0.0,
    List<WizardAsset>? assets,
  })  : id = id ?? const Uuid().v4(),
        assets = assets ?? [];

  bool get isValid =>
      name.trim().isNotEmpty &&
      institutionName.trim().isNotEmpty &&
      cashBalance >= 0;

  double get totalAssetsValue => assets.fold(
      0.0, (sum, asset) => sum + (asset.quantity * asset.currentPrice));

  double get totalValue => cashBalance + totalAssetsValue;
}

/// Représente un actif temporaire pendant le wizard
class WizardAsset {
  final String id;
  String ticker;
  String name;
  AssetType? type;
  double quantity;
  double averagePrice; // PRU
  double currentPrice; // Prix actuel
  double? estimatedYield; // Rendement annuel estimé (%)
  DateTime firstPurchaseDate;

  WizardAsset({
    String? id,
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.firstPurchaseDate,
    this.type,
    this.estimatedYield,
  }) : id = id ?? const Uuid().v4();

  bool get isValid =>
      ticker.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      quantity > 0 &&
      averagePrice > 0 &&
      currentPrice > 0;

  double get totalValue => quantity * currentPrice;
}

