// lib/core/data/models/asset.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:hive/hive.dart';
import 'transaction.dart';
import 'transaction_type.dart';
import 'asset_type.dart';
import 'repayment_type.dart';

part 'asset.g.dart';

// ignore_for_file: deprecated_member_use_from_same_package

@HiveType(typeId: 3)
class Asset {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String ticker;

  // --- CHAMPS PERIMES (GARDÉS POUR LA MIGRATION) ---
  @HiveField(2)
  @Deprecated('Use transactions instead')
  double? staleQuantity;

  @HiveField(3)
  @Deprecated('Use transactions instead')
  double? staleAveragePrice;
  // --- FIN CHAMPS PERIMES ---

  // --- REFRACTORING ---
  double currentPrice; // n'est plus 'final'
  double estimatedAnnualYield;
  // --- FIN REFRACTORING ---

  // --- NOUVEAUX CHAMPS (POUR CALCULS DEVISES) ---
  /// Devise du prix (ex: "USD"), injecté depuis AssetMetadata
  String priceCurrency;

  /// Taux de change ACTUEL (priceCurrency -> account.currency)
  /// Injecté par le Repository lors de l'hydratation
  double currentExchangeRate;
  // --- FIN NOUVEAUX CHAMPS ---

  @HiveField(6)
  final String id;

  @HiveField(7)
  final AssetType type;

  // --- CROWDFUNDING IMMOBILIER ---
  @HiveField(9)
  String? projectName;

  @HiveField(10)
  String? location;

  @HiveField(11)
  int? minDuration;

  @HiveField(12)
  int? targetDuration;

  @HiveField(13)
  int? maxDuration;

  @HiveField(14)
  double? expectedYield;

  @HiveField(15)
  RepaymentType? repaymentType;

  @HiveField(16)
  String? riskRating;

  @HiveField(17)
  double? latitude;

  @HiveField(18)
  double? longitude;
  // --- FIN CROWDFUNDING ---

  // Injecté par le getter `Account.assets`
  List<Transaction> transactions = [];

  /// Transactions passées (exclut les transactions futures)
  List<Transaction> get _pastTransactions {
    final now = DateTime.now();
    return transactions.where((tr) => tr.date.isBefore(now) || tr.date.isAtSameMomentAs(now)).toList();
  }

  // NOUVEAU : Getter pour la quantité
  double get quantity {
    if (_pastTransactions.isEmpty) return 0.0;
    return _pastTransactions.fold(0.0, (sum, tr) {
      if (tr.type == TransactionType.Buy) {
        return sum + (tr.quantity ?? 0.0);
      }
      if (tr.type == TransactionType.Sell) {
        return sum - (tr.quantity ?? 0.0);
      }
      return sum;
    });
  }

  // MODIFIÉ : Getter pour le PRU (en devise d'ACTIF)
  // Conforme à l'étape 1.3 de la feuille de route
  double get averagePrice {
    if (_pastTransactions.isEmpty) return 0.0;
    final buyTransactions =
    _pastTransactions.where((tr) => tr.type == TransactionType.Buy).toList();
    if (buyTransactions.isEmpty) return 0.0;

    double totalCostInAssetCurrency = 0.0; // En devise d'actif (ex: USD)
    double totalQuantity = 0.0;
    for (final tr in buyTransactions) {
      final qty = tr.quantity ?? 0.0;
      final price = tr.price ?? 0.0; // En devise d'actif (USD)
      final fees = tr.fees; // En devise de compte (EUR)
      final rate = tr.exchangeRate ?? 1.0; // Taux (USD -> EUR)

      // Convertir les frais de la devise du compte (EUR) vers la devise de l'actif (USD)
      // fraisUSD = fraisEUR / taux(USD->EUR)
      final feesInAssetCurrency = (rate == 0) ? 0.0 : (fees / rate);

      totalCostInAssetCurrency += (qty * price) + feesInAssetCurrency;
      totalQuantity += qty;
    }

    if (totalQuantity == 0) return 0.0;
    return totalCostInAssetCurrency / totalQuantity;
  }

  Asset({
    required this.id,
    required this.name,
    required this.ticker,
    AssetType? type,
    this.transactions = const [],
    // --- REFRACTORING ---
    this.currentPrice = 0.0,
    this.estimatedAnnualYield = 0.0,
    // --- NOUVEAUX CHAMPS (avec valeurs par défaut) ---
    this.priceCurrency = 'EUR',
    this.currentExchangeRate = 1.0,
    // --- FIN NOUVEAUX CHAMPS ---

    // --- CROWDFUNDING ---
    this.projectName,
    this.location,
    this.minDuration,
    this.targetDuration,
    this.maxDuration,
    this.expectedYield,
    this.repaymentType,
    this.riskRating,
    // --- FIN CROWDFUNDING ---

    // Champs de migration
    this.staleQuantity,
    this.staleAveragePrice,
  }) : type = type ?? AssetType.Other;

  // MODIFIÉ : Valeur totale en devise de COMPTE
  // Conforme à l'étape 1.3 de la feuille de route
  double get totalValue {
    if (type == AssetType.RealEstateCrowdfunding) {
      // Calcul spécifique Crowdfunding : Capital Investi + Intérêts courus
      double totalBuyValueWithInterest = 0.0;
      double totalBuyQuantity = 0.0;

      final buyTransactions = _pastTransactions.where((tr) => tr.type == TransactionType.Buy);

      for (final tr in buyTransactions) {
        final qty = tr.quantity ?? 0.0;
        final price = tr.price ?? 0.0;
        final invested = qty * price;
        final yieldPercent = (expectedYield ?? 0.0) / 100.0;
        final daysSince = DateTime.now().difference(tr.date).inDays;
        // On ne compte pas d'intérêts négatifs si date future
        final duration = daysSince < 0 ? 0 : daysSince;

        final interest = invested * yieldPercent * (duration / 365.0);
        totalBuyValueWithInterest += invested + interest;
        totalBuyQuantity += qty;
      }

      if (totalBuyQuantity == 0) return 0.0;

      // Ratio de détention (si on a vendu une partie)
      final holdingRatio = quantity / totalBuyQuantity;

      // Valeur ajustée
      final adjustedValue = totalBuyValueWithInterest * holdingRatio;

      return adjustedValue * currentExchangeRate;
    }

    // (Quantité) * (Prix en USD) * (Taux USD -> EUR Compte)
    return quantity * currentPrice * currentExchangeRate;
  }

  // MODIFIÉ : Plus/Moins-value en devise de COMPTE
  // Conforme à l'étape 1.3 de la feuille de route
  double get profitAndLoss {
    // totalValue et totalInvestedCapital sont maintenant tous les deux
    // dans la devise du COMPTE, le calcul est donc direct.
    return totalValue - totalInvestedCapital;
  }

  // MODIFIÉ : Capital investi (coût total d'acquisition en devise de COMPTE)
  // Conforme à l'étape 1.3 de la feuille de route
  double get totalInvestedCapital {
    final buyTransactions =
    _pastTransactions.where((tr) => tr.type == TransactionType.Buy).toList();
    if (buyTransactions.isEmpty) return 0.0;

    // Calcule le coût total d'acquisition dans la devise du COMPTE
    double totalCostInAccountCurrency = 0.0;
    for (final tr in buyTransactions) {
      // tr.amount est négatif et représente (qty * price * rate) en devise de COMPTE
      // tr.fees est déjà dans la devise du COMPTE
      totalCostInAccountCurrency += (-tr.amount) + tr.fees;
    }
    return totalCostInAccountCurrency;
  }

  double get profitAndLossPercentage {
    if (totalInvestedCapital == 0) return 0.0;
    return profitAndLoss / totalInvestedCapital;
  }

  Asset deepCopy() {
    return Asset(
      id: id,
      name: name,
      ticker: ticker,
      type: type,
      currentPrice: currentPrice,
      estimatedAnnualYield: estimatedAnnualYield,
      priceCurrency: priceCurrency, // <-- AJOUT
      currentExchangeRate: currentExchangeRate, // <-- AJOUT
      transactions: List.from(transactions),

      // --- CROWDFUNDING ---
      projectName: projectName,
      location: location,
      minDuration: minDuration,
      targetDuration: targetDuration,
      maxDuration: maxDuration,
      expectedYield: expectedYield,
      repaymentType: repaymentType,
      riskRating: riskRating,
      // --- FIN CROWDFUNDING ---

      // Champs de migration
      staleQuantity: staleQuantity,
      staleAveragePrice: staleAveragePrice,
    );
  }
}