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
    final ratesResult = await _fetchExchangeRates(portfolio, targetCurrency);
    final rates = ratesResult.rates;
    final failedConversions = ratesResult.failed;
    
    debugPrint("    -> ✅ Taux de change récupérés: $rates");
    if (failedConversions.isNotEmpty) {
      debugPrint("    -> ⚠️ Echecs de conversion: $failedConversions");
    }

    // 2. Calculer les valeurs converties
    final result = _computeAggregatedData(
      portfolio: portfolio,
      targetCurrency: targetCurrency,
      rates: rates,
      allMetadata: allMetadata,
      failedConversions: failedConversions,
    );

    debugPrint("    -> ✅ Calculs terminés.");
    debugPrint("    ->     Valeur Totale FINALE: ${result.totalValue} $targetCurrency");
    debugPrint("    --- ⚙️ FIN CalculationService.calculate ---");

    return result;
  }

  Future<({Map<String, double> rates, List<String> failed})> _fetchExchangeRates(
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
    final failed = <String>[];

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
          failed.add(accountCurrency);
          // rethrow; // <-- SUPPRIMÉ
          // --- ▲▲▲ FIN CORRECTION ▲▲▲
        }
      }),
    );

    return (rates: rates, failed: failed);
  }

  AggregatedPortfolioData _computeAggregatedData({
    required Portfolio portfolio,
    required String targetCurrency,
    required Map<String, double> rates,
    required Map<String, AssetMetadata> allMetadata,
    required List<String> failedConversions,
  }) {
    double totalValue = 0.0;
    double totalPL = 0.0;
    double totalInvested = 0.0;
    double weightedYieldSum = 0.0; // NOUVEAU

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
        if (accCash != 0) {
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

          // Calcul du rendement pondéré
          weightedYieldSum += assetValueConverted * asset.estimatedAnnualYield;

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

    // Calcul final du rendement
    final estimatedAnnualYield = totalValue > 0 ? weightedYieldSum / totalValue : 0.0;

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
      estimatedAnnualYield: estimatedAnnualYield,
      failedConversions: failedConversions,
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
          type: firstAsset.type,
        ));
      }
    });

    aggregatedAssets.sort((a, b) => b.totalValue.compareTo(a.totalValue));
    return aggregatedAssets;
  }
}