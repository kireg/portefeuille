// lib/core/data/models/account.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // <--- NOUVEL IMPORT
import 'asset.dart';
import 'account_type.dart';
import 'transaction.dart';
import 'transaction_type.dart'; // <--- NOUVEL IMPORT
import 'asset_type.dart';

part 'account.g.dart';

@HiveType(typeId: 2)
class Account {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final AccountType type;

  @HiveField(2)
  @deprecated
  List<Asset>? stale_assets;

  @HiveField(3)
  @deprecated
  double? stale_cashBalance;

  @HiveField(4)
  final String id;

  // --- NOUVEAU CHAMP ---
  @HiveField(5)
  final String? currency;
  // Ex: "EUR", "USD" - Nullable pour compatibilité
  // --- FIN NOUVEAU ---

  // Getter pour garantir une devise par défaut
  String get activeCurrency => currency ?? 'EUR';

  // Doit être injecté par le Repository
  List<Transaction> transactions = [];

  // -----------------------------------------------------------------
  // ▼▼▼ CORRECTION PRINCIPALE ▼▼▼
  // -----------------------------------------------------------------

  // 'assets' est maintenant un CHAMP (rempli par le Repository)
  // et non plus un getter calculé.
  List<Asset> assets = [];

  // --- L'ANCIEN GETTER 'get assets' EST COMPLÈTEMENT SUPPRIMÉ ---

  // -----------------------------------------------------------------
  // ▲▲▲ FIN CORRECTION ▲▲▲
  // -----------------------------------------------------------------


  // NOUVEAU : Outil pour générer des ID d'Assets
  static const _uuid = Uuid();

  // NOUVEAU : Le solde est maintenant un getter (INCHANGÉ, C'ÉTAIT CORRECT)
  double get cashBalance {
    if (transactions.isEmpty) return 0.0;
    // 'totalAmount' inclut déjà le signe (négatif pour Achat, positif pour Vente/Dépôt)
    // et soustrait les frais.
    return transactions.fold(0.0, (sum, tr) => sum + tr.totalAmount);
  }

  // -----------------------------------------------------------------
  // ▼▼▼ NOUVELLE MÉTHODE STATIQUE (LOGIQUE DE L'ANCIEN GETTER) ▼▼▼
  // -----------------------------------------------------------------

  /// Méthode statique pour générer des actifs "stupides" (prix=0)
  /// Appelée par le PortfolioRepository lors du chargement.
  static List<Asset> generateAssetsFromTransactions(List<Transaction> transactions) {
    final assetTransactions = transactions
        .where((tr) =>
    tr.type == TransactionType.Buy || tr.type == TransactionType.Sell)
        .toList();
    if (assetTransactions.isEmpty) return [];

    // Grouper les transactions par ticker
    final Map<String, List<Transaction>> groupedByTicker = {};
    for (final tr in assetTransactions) {
      if (tr.assetTicker != null) {
        (groupedByTicker[tr.assetTicker!] ??= []).add(tr);
      }
    }

    // Créer les objets Asset
    final List<Asset> generatedAssets = [];
    groupedByTicker.forEach((ticker, tickerTransactions) {
      // Trouver la transaction la plus récente pour obtenir le nom
      final lastTx =
      tickerTransactions.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

      // Créer l'objet Asset.
      // Le 'currentPrice' et 'yield' seront à 0.0 par défaut.
      // Le PortfolioHydrationService les mettra à jour.
      final asset = Asset(
        id: _uuid.v4(), // Génère un ID unique pour cet objet en mémoire
        name: lastTx.assetName ?? ticker,
        ticker: ticker,
        type: lastTx.assetType ?? AssetType.Other,
        transactions: tickerTransactions,
        // currentPrice et estimatedAnnualYield sont à 0.0 par défaut
      );

      // N'ajoute pas l'actif si la quantité est nulle (tout vendu)
      if (asset.quantity > 0) {
        generatedAssets.add(asset);
      }
    });
    return generatedAssets;
  }

  // -----------------------------------------------------------------
  // ▲▲▲ FIN NOUVELLE MÉTHODE ▲▲▲
  // -----------------------------------------------------------------


  Account({
    required this.id,
    required this.name,
    required this.type,
    this.currency = 'EUR', // <-- MODIFIÉ (défaut)
    this.transactions = const [],
    // Migration
    this.stale_assets,
    this.stale_cashBalance,
  });

  // Les getters suivants sont MAINTENANT CORRECTS car ils liront
  // le CHAMP 'assets' qui est hydraté, au lieu de l'ancien getter.

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
    // Éviter la division par zéro si assetsValue est nul
    if (assetsValue == 0) return 0.0;
    return weightedYield / assetsValue;
  }

  Account deepCopy() {
    // Note: Le deepCopy doit aussi copier les assets maintenant
    // S'ils ne sont pas copiés, l'hydratation pourrait modifier l'original
    return Account(
      id: id,
      name: name,
      type: type,
      currency: currency, // <-- MODIFIÉ
      transactions: List.from(transactions),
      // Migration
      stale_assets: stale_assets?.map((e) => e.deepCopy()).toList(),
      stale_cashBalance: stale_cashBalance,
    )
    // Assigner les assets générés au champ
      ..assets = assets.map((e) => e.deepCopy()).toList();
  }
}