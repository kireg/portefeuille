// lib/core/data/models/account.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/utils/enum_helpers.dart'; // NOUVEL IMPORT
import 'asset.dart';
import 'account_type.dart';
import 'transaction.dart';
import 'transaction_type.dart';
import 'asset_type.dart';

part 'account.g.dart';

@HiveType(typeId: 2)
class Account {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final AccountType type;

  @HiveField(2)
  @Deprecated('Use assets instead')
  List<Asset>? staleAssets;

  @HiveField(3)
  @Deprecated('Use transactions instead')
  double? staleCashBalance;

  @HiveField(4)
  final String id;

  @HiveField(5)
  final String? currency;
  String get activeCurrency => currency ?? 'EUR';

  // Champs hydratés (NON stockés dans Hive, NON inclus dans JSON)
  List<Transaction> transactions = [];
  List<Asset> assets = [];

  static const _uuid = Uuid();

  // ... (tous vos getters et méthodes : cashBalance, generateAssetsFromTransactions, etc. restent inchangés) ...

  double get cashBalance {
    if (transactions.isEmpty) return 0.0;
    return transactions.fold(0.0, (sum, tr) => sum + tr.totalAmount);
  }

  static List<Asset> generateAssetsFromTransactions(List<Transaction> transactions) {
    final assetTransactions = transactions
        .where((tr) =>
    tr.type == TransactionType.Buy || tr.type == TransactionType.Sell)
        .toList();
    if (assetTransactions.isEmpty) return [];

    final Map<String, List<Transaction>> groupedByTicker = {};
    for (final tr in assetTransactions) {
      if (tr.assetTicker != null) {
        (groupedByTicker[tr.assetTicker!] ??= []).add(tr);
      }
    }

    final List<Asset> generatedAssets = [];
    groupedByTicker.forEach((ticker, tickerTransactions) {
      final lastTx =
      tickerTransactions.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
      final asset = Asset(
        id: _uuid.v4(),
        name: lastTx.assetName ?? ticker,
        ticker: ticker,
        type: lastTx.assetType ?? AssetType.Other,
        transactions: tickerTransactions,
      );
      if (asset.quantity > 0) {
        generatedAssets.add(asset);
      }
    });
    return generatedAssets;
  }

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.currency = 'EUR',
    this.transactions = const [],
    // Migration
    this.staleAssets,
    this.staleCashBalance,
  }) {
    // Hydrate automatiquement les assets à partir des transactions
    assets = generateAssetsFromTransactions(transactions);
  }

  double get totalValue {
    final assetsValue =
    assets.fold(0.0, (sum, asset) => sum + asset.totalValue);
    return assetsValue + cashBalance;
  }

  double get profitAndLoss {
    return assets.fold(0.0, (sum, asset) => sum + asset.profitAndLoss);
  }

  double get totalInvestedCapital {
    return assets.fold(0.0, (sum, asset) => sum + asset.totalInvestedCapital);
  }

  double get estimatedAnnualYield {
    final assetsValue =
    assets.fold(0.0, (sum, asset) => sum + asset.totalValue);
    if (assetsValue == 0) {
      return 0.0;
    }
    final weightedYield = assets.fold(
        0.0,
            (sum, asset) =>
        sum + (asset.totalValue * asset.estimatedAnnualYield));
    if (assetsValue == 0) return 0.0;
    return weightedYield / assetsValue;
  }

  Account deepCopy() {
    return Account(
      id: id,
      name: name,
      type: type,
      currency: currency,
      transactions: List.from(transactions),
      staleAssets: staleAssets?.map((e) => e.deepCopy()).toList(),
      staleCashBalance: staleCashBalance,
    )
      ..assets = assets.map((e) => e.deepCopy()).toList();
  }

  // --- NOUVELLES MÉTHODES JSON ---
  // Note : transactions et assets sont exclus car ils sont hydratés
  // au chargement. Les champs 'stale_' sont exclus car obsolètes.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': enumToString(type),
      'currency': currency,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      type: enumFromString(
        AccountType.values,
        json['type'],
        fallback: AccountType.cto,
      ),
      currency: json['currency'] as String? ?? 'EUR',
      // transactions et assets seront (re)créés vides par défaut
    );
  }
// --- FIN NOUVELLES MÉTHODES JSON ---
}

// ignore_for_file: deprecated_member_use_from_same_package