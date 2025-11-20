// lib/features/00_app/services/calculation_service.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/aggregated_asset.dart';
import 'package:portefeuille/core/data/models/aggregated_portfolio_data.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/price_history_point.dart';
import 'package:portefeuille/core/data/models/exchange_rate_history.dart';
import 'package:portefeuille/core/data/models/history_point.dart';
import 'package:portefeuille/core/data/models/account.dart';

class CalculationService {
  final ApiService _apiService;

  CalculationService({
    required ApiService apiService,
  }) : _apiService = apiService;

  /// Calcule toutes les valeurs converties pour un portefeuille.
  Future<AggregatedPortfolioData> calculate({
    required Portfolio? portfolio,
    required String targetCurrency,
    required Map<String, AssetMetadata> allMetadata,
  }) async {
    debugPrint("    --- ⚙️ DÉBUT CalculationService.calculate ---");
    debugPrint("    -> Devise Cible: $targetCurrency");

    if (portfolio == null) {
      debugPrint("    -> ⚠️ Portfolio NULL. Retour vide.");
      return AggregatedPortfolioData.empty;
    }

    // 1. Récupérer tous les taux de change nécessaires
    final rates = await _fetchExchangeRates(portfolio, targetCurrency);
    debugPrint("    -> ✅ Taux de change récupérés: $rates");

    // 2. Calculer les valeurs converties
    final result = _computeAggregatedData(
      portfolio: portfolio,
      targetCurrency: targetCurrency,
      rates: rates,
      allMetadata: allMetadata,
    );

    debugPrint("    -> ✅ Calculs terminés.");
    debugPrint("    ->     Valeur Totale FINALE: ${result.totalValue} $targetCurrency");
    debugPrint("    --- ⚙️ FIN CalculationService.calculate ---");

    return result;
  }

  Future<Map<String, double>> _fetchExchangeRates(
      Portfolio portfolio,
      String targetCurrency,
      ) async {
    // Collecter toutes les devises de compte uniques
    final accountCurrencies = portfolio.institutions
        .expand((inst) => inst.accounts)
        .map((acc) => acc.activeCurrency)
        .toSet();

    debugPrint("    -> Devises de compte trouvées: $accountCurrencies");

    final rates = <String, double>{};

    await Future.wait(
      accountCurrencies.map((accountCurrency) async {
        if (accountCurrency == targetCurrency) {
          rates[accountCurrency] = 1.0;
          return;
        }

        try {
          rates[accountCurrency] = await _apiService.getExchangeRate(
            accountCurrency,
            targetCurrency,
          );
        } catch (e) {
          // --- ▼▼▼ CORRECTION : NE PLUS PROPAGER L'ERREUR ▼▼▼ ---
          // (Notre ApiService a déjà essayé d'utiliser le cache obsolète)
          // S'il y a toujours une erreur, c'est que le cache est vide ET l'API indisponible.
          // On utilise 1.0 comme fallback pour ne pas bloquer le chargement.
          debugPrint(
              "    -> ❌ ERREUR FATALE Taux pour $accountCurrency -> $targetCurrency: $e");
          debugPrint(
              "    -> ⚠️ (L'API a échoué ET le cache était vide). Utilisation du taux de 1.0 comme fallback.");
          rates[accountCurrency] = 1.0;
          // rethrow; // <-- SUPPRIMÉ
          // --- ▲▲▲ FIN CORRECTION ▲▲▲
        }
      }),
    );

    return rates;
  }

  AggregatedPortfolioData _computeAggregatedData({
    required Portfolio portfolio,
    required String targetCurrency,
    required Map<String, double> rates,
    required Map<String, AssetMetadata> allMetadata,
  }) {
    double totalValue = 0.0;
    double totalPL = 0.0;
    double totalInvested = 0.0;

    final accountValues = <String, double>{};
    final accountPLs = <String, double>{};
    final accountInvested = <String, double>{};
    final assetValues = <String, double>{};
    final assetPLs = <String, double>{};
    final aggregatedValueByType = <AssetType, double>{};
    final assetsByTicker = <String, List<Asset>>{};
    final ratesByTicker = <String, List<double>>{};

    for (final inst in portfolio.institutions) {
      for (final acc in inst.accounts) {
        final rate = rates[acc.activeCurrency] ?? 1.0;

        // Calculs par Compte
        final accValue = acc.totalValue * rate;
        final accPL = acc.profitAndLoss * rate;
        final accInvested = acc.totalInvestedCapital * rate;
        final accCash = acc.cashBalance * rate;

        totalValue += accValue;
        totalPL += accPL;
        totalInvested += accInvested;

        accountValues[acc.id] = accValue;
        accountPLs[acc.id] = accPL;
        accountInvested[acc.id] = accInvested;

        // Agrégation Cash
        if (accCash > 0) {
          aggregatedValueByType.update(
            AssetType.Cash,
                (value) => value + accCash,
            ifAbsent: () => accCash,
          );
        }

        // Calculs par Actif
        for (final asset in acc.assets) {
          final assetValueConverted = asset.totalValue * rate;
          final assetPLConverted = asset.profitAndLoss * rate;

          assetValues[asset.id] = assetValueConverted;
          assetPLs[asset.id] = assetPLConverted;

          aggregatedValueByType.update(
            asset.type,
                (value) => value + assetValueConverted,
            ifAbsent: () => assetValueConverted,
          );

          (assetsByTicker[asset.ticker] ??= []).add(asset);
          (ratesByTicker[asset.ticker] ??= []).add(rate);
        }
      }
    }

    // Agrégation par Ticker
    final aggregatedAssets = _buildAggregatedAssets(
      assetsByTicker: assetsByTicker,
      ratesByTicker: ratesByTicker,
      targetCurrency: targetCurrency,
      allMetadata: allMetadata,
    );

    return AggregatedPortfolioData(
      baseCurrency: targetCurrency,
      totalValue: totalValue,
      totalPL: totalPL,
      totalInvested: totalInvested,
      accountValues: accountValues,
      accountPLs: accountPLs,
      accountInvested: accountInvested,
      assetTotalValues: assetValues,
      assetPLs: assetPLs,
      aggregatedAssets: aggregatedAssets,
      valueByAssetType: aggregatedValueByType,
    );
  }

  List<AggregatedAsset> _buildAggregatedAssets({
    required Map<String, List<Asset>> assetsByTicker,
    required Map<String, List<double>> ratesByTicker,
    required String targetCurrency,
    required Map<String, AssetMetadata> allMetadata,
  }) {
    final aggregatedAssets = <AggregatedAsset>[];

    assetsByTicker.forEach((ticker, assets) {
      if (assets.isEmpty) return;

      final ratesForTicker = ratesByTicker[ticker]!;

      double aggQuantity = 0;
      double aggTotalValue = 0;
      double aggTotalPL = 0;
      double aggTotalInvested = 0;
      double aggWeightedPRU = 0;
      double aggWeightedCurrentPrice = 0;

      for (int i = 0; i < assets.length; i++) {
        final asset = assets[i];
        final rate = ratesForTicker[i];

        final convertedValue = asset.totalValue * rate;
        final convertedPL = asset.profitAndLoss * rate;
        final convertedInvested = asset.totalInvestedCapital * rate;
        final convertedCurrentPrice =
            asset.currentPrice * asset.currentExchangeRate * rate;
        final convertedAvgPrice =
            asset.averagePrice * asset.currentExchangeRate * rate;

        aggQuantity += asset.quantity;
        aggTotalValue += convertedValue;
        aggTotalPL += convertedPL;
        aggTotalInvested += convertedInvested;
        aggWeightedPRU += convertedAvgPrice * asset.quantity;
        aggWeightedCurrentPrice += convertedCurrentPrice * asset.quantity;
      }

      final finalPRU = (aggQuantity > 0) ? aggWeightedPRU / aggQuantity : 0.0;
      final finalCurrentPrice =
      (aggQuantity > 0) ? aggWeightedCurrentPrice / aggQuantity : 0.0;
      final finalPLPercentage =
      (aggTotalInvested > 0) ? aggTotalPL / aggTotalInvested : 0.0;

      if (aggQuantity > 0) {
        final firstAsset = assets.first;
        aggregatedAssets.add(AggregatedAsset(
          ticker: ticker,
          name: firstAsset.name,
          quantity: aggQuantity,
          averagePrice: finalPRU,
          currentPrice: finalCurrentPrice,
          totalValue: aggTotalValue,
          profitAndLoss: aggTotalPL,
          profitAndLossPercentage: finalPLPercentage,
          estimatedAnnualYield: firstAsset.estimatedAnnualYield,
          metadata: allMetadata[ticker],
          assetCurrency: firstAsset.priceCurrency,
          baseCurrency: targetCurrency,
        ));
      }
    });

    aggregatedAssets.sort((a, b) => b.totalValue.compareTo(a.totalValue));
    return aggregatedAssets;
  }

  Future<List<HistoryPoint>> calculateHistory({
    required Portfolio portfolio,
    required List<Transaction> transactions,
    required List<PriceHistoryPoint> priceHistory,
    required List<ExchangeRateHistory> rateHistory,
    required String targetCurrency,
    required Map<String, AssetMetadata> allMetadata,
  }) async {
    if (transactions.isEmpty) return [];

    // Sort transactions by date
    transactions.sort((a, b) => a.date.compareTo(b.date));

    final startDate = transactions.first.date;
    final endDate = DateTime.now();
    final history = <HistoryPoint>[];

    // Maps for fast access
    // Price History: Ticker -> Date -> Price
    final priceMap = <String, Map<DateTime, double>>{};
    for (var p in priceHistory) {
      final dateKey = DateTime(p.date.year, p.date.month, p.date.day);
      (priceMap[p.ticker] ??= {})[dateKey] = p.price;
    }

    // Exchange Rate History: Pair -> Date -> Rate
    final rateMap = <String, Map<DateTime, double>>{};
    for (var r in rateHistory) {
      final dateKey = DateTime(r.date.year, r.date.month, r.date.day);
      (rateMap[r.pair] ??= {})[dateKey] = r.rate;
    }

    // Current quantities: AccountId -> Ticker -> Quantity
    final currentQuantities = <String, Map<String, double>>{};
    
    // Current cash: AccountId -> Cash
    final currentCash = <String, double>{};

    // Optimization: Keep track of last known prices and rates
    final lastKnownPrices = <String, double>{};
    final lastKnownRates = <String, double>{}; // Pair -> Rate

    // Helper to get rate from lastKnownRates
    double getRate(String from, String to) {
      if (from == to) return 1.0;
      
      final pair1 = '$from-$to';
      if (lastKnownRates.containsKey(pair1)) return lastKnownRates[pair1]!;
      
      final pair2 = '$to-$from';
      if (lastKnownRates.containsKey(pair2)) return 1.0 / lastKnownRates[pair2]!;
      
      return 1.0; // Fallback
    }

    int txIndex = 0;

    // Iterate day by day
    for (var day = startDate;
        day.isBefore(endDate) || day.isAtSameMomentAs(endDate);
        day = day.add(const Duration(days: 1))) {
      
      final dateKey = DateTime(day.year, day.month, day.day);

      // 1. Apply transactions for this day
      while (txIndex < transactions.length &&
          transactions[txIndex].date.isBefore(day.add(const Duration(days: 1)))) {
        final tx = transactions[txIndex];
        
        // Update Cash
        currentCash[tx.accountId] = (currentCash[tx.accountId] ?? 0.0) + tx.totalAmount;

        // Update Quantities
        if (tx.assetTicker != null) {
          final accountQuantities = currentQuantities[tx.accountId] ??= {};
          if (tx.type == TransactionType.Buy) {
            accountQuantities[tx.assetTicker!] =
                (accountQuantities[tx.assetTicker!] ?? 0.0) + (tx.quantity ?? 0.0);
          } else if (tx.type == TransactionType.Sell) {
            accountQuantities[tx.assetTicker!] =
                (accountQuantities[tx.assetTicker!] ?? 0.0) - (tx.quantity ?? 0.0);
          }
        }
        txIndex++;
      }

      // 2. Update last known prices and rates for this day
      for (var ticker in priceMap.keys) {
        final prices = priceMap[ticker]!;
        if (prices.containsKey(dateKey)) {
          lastKnownPrices[ticker] = prices[dateKey]!;
        }
      }
      
      for (var pair in rateMap.keys) {
        final rates = rateMap[pair]!;
        if (rates.containsKey(dateKey)) {
          lastKnownRates[pair] = rates[dateKey]!;
        }
      }

      // 3. Calculate Total Value
      double dailyTotal = 0.0;

      // Cash Value
      for (var entry in currentCash.entries) {
        final accountId = entry.key;
        final cash = entry.value;
        
        Account? account;
        for (var inst in portfolio.institutions) {
          for (var acc in inst.accounts) {
            if (acc.id == accountId) {
              account = acc;
              break;
            }
          }
          if (account != null) break;
        }
            
        if (account != null) {
             final rate = getRate(account.activeCurrency, targetCurrency);
             dailyTotal += cash * rate;
        }
      }

      // Assets Value
      for (var accountId in currentQuantities.keys) {
        Account? account;
        for (var inst in portfolio.institutions) {
          for (var acc in inst.accounts) {
            if (acc.id == accountId) {
              account = acc;
              break;
            }
          }
          if (account != null) break;
        }

        if (account == null) continue;

        final accountCurrency = account.activeCurrency;
        final accountToBaseRate = getRate(accountCurrency, targetCurrency);

        final accountQuantities = currentQuantities[accountId]!;
        for (var entry in accountQuantities.entries) {
            final ticker = entry.key;
            final quantity = entry.value;
            if (quantity <= 0) continue;
            
            final price = lastKnownPrices[ticker] ?? 0.0;
            final metadata = allMetadata[ticker];
            final assetCurrency = metadata?.priceCurrency ?? 'EUR';
            
            final assetToAccountRate = getRate(assetCurrency, accountCurrency);
            
            // Value in Account Currency
            final valueInAccount = quantity * price * assetToAccountRate;
            
            // Value in Base Currency
            dailyTotal += valueInAccount * accountToBaseRate;
        }
      }
      
      history.add(HistoryPoint(day, dailyTotal));
    }
    
    return history;
  }
}