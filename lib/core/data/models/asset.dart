// lib/core/data/models/asset.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:hive/hive.dart';
import 'transaction.dart';
import 'transaction_type.dart'; // <--- NOUVEL IMPORT
import 'asset_type.dart';

part 'asset.g.dart';

@HiveType(typeId: 3)
class Asset {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String ticker;

  // --- CHAMPS PERIMES (GARDÉS POUR LA MIGRATION) --- // <--- CORRIGÉ
  @HiveField(2)
  @deprecated
  double? stale_quantity;

  @HiveField(3)
  @deprecated
  double? stale_averagePrice;
  // --- FIN CHAMPS PERIMES --- // <--- CORRIGÉ

  // --- REFRACTORING ---
  // Ces champs ne sont plus stockés dans Hive (car Asset n'est plus dans Account)
  // Ils sont calculés ou mis à jour en mémoire par le Provider.
  // @HiveField(4) // <--- SUPPRIMÉ
  double currentPrice; // <--- n'est plus 'final'

  // @HiveField(5) // <--- SUPPRIMÉ
  double estimatedAnnualYield;
  // --- FIN REFRACTORING ---

  @HiveField(6)
  final String id;

  @HiveField(7)
  final AssetType type;

  // Injecté par le getter `Account.assets`
  List<Transaction> transactions = [];

  // NOUVEAU : Getter pour la quantité
  double get quantity {
    if (transactions.isEmpty) return 0.0;
    return transactions.fold(0.0, (sum, tr) {
      if (tr.type == TransactionType.Buy) {
        return sum + (tr.quantity ?? 0.0);
      }
      if (tr.type == TransactionType.Sell) {
        return sum - (tr.quantity ?? 0.0);
      }
      return sum;
    });
  }

  // NOUVEAU : Getter pour le PRU
  double get averagePrice {
    if (transactions.isEmpty) return 0.0;
    final buyTransactions =
        transactions.where((tr) => tr.type == TransactionType.Buy).toList();
    if (buyTransactions.isEmpty) return 0.0;

    double totalCost = 0.0;
    double totalQuantity = 0.0;
    for (final tr in buyTransactions) {
      final qty = tr.quantity ?? 0.0;
      final price = tr.price ?? 0.0;
      totalCost += (qty * price) + tr.fees;
      totalQuantity += qty;
    }

    if (totalQuantity == 0) return 0.0;
    return totalCost / totalQuantity;
  }

  Asset({
    required this.id,
    required this.name,
    required this.ticker,
    AssetType? type, // <--- MODIFICATION 1: Retrait de 'required'
    this.transactions = const [],
    // --- REFRACTORING (champs optionnels) ---
    this.currentPrice = 0.0,
    this.estimatedAnnualYield = 0.0,
    // --- FIN REFRACTORING ---

    // Champs de migration
    this.stale_quantity,
    this.stale_averagePrice,
  }) : type = type ??
            AssetType.Other; // <--- MODIFICATION 2: Assignation par défaut

  double get totalValue => quantity * currentPrice;

  double get profitAndLoss => (currentPrice - averagePrice) * quantity;

  // NOUVEAU : Capital investi (coût total d'acquisition)
  double get totalInvestedCapital => averagePrice * quantity;

  double get profitAndLossPercentage {
    if (averagePrice == 0) return 0.0;
    return (currentPrice / averagePrice - 1);
  }

  Asset deepCopy() {
    return Asset(
      id: id,
      name: name,
      ticker: ticker,
      type: type,
      currentPrice: currentPrice,
      estimatedAnnualYield: estimatedAnnualYield,
      transactions: List.from(transactions),

      // Champs de migration
      stale_quantity: stale_quantity,
      stale_averagePrice: stale_averagePrice,
    );
  }
}
