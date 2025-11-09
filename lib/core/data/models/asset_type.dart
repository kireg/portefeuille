// lib/core/data/models/asset_type.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:hive/hive.dart';

part 'asset_type.g.dart';

@HiveType(typeId: 8) // IMPORTANT: Utilisez un ID non utilisé (ex: 8)
enum AssetType {
  @HiveField(0)
  Stock, // Action

  @HiveField(1)
  ETF, // Fonds Négocié en Bourse

  @HiveField(2)
  Crypto, // Crypto-monnaie

  @HiveField(3)
  Bond, // Obligation

  @HiveField(4)
  Other, // Autre

  // --- NOUVEAU ---
  @HiveField(5)
  Cash, // Liquidités
  // --- FIN NOUVEAU ---
}

/// Extension pour la traduction
extension AssetTypeExtension on AssetType {
  String get displayName {
    switch (this) {
      case AssetType.Stock:
        return 'Action';
      case AssetType.ETF:
        return 'ETF';
      case AssetType.Crypto:
        return 'Crypto';
      case AssetType.Bond:
        return 'Obligation';
      case AssetType.Cash:
        return 'Liquidités';
      case AssetType.Other:
        return 'Autre';
    }
  }
}