// lib/features/00_app/providers/portfolio_hydration_service.dart
// FICHIER MODIFIÉ

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
// NOUVEL IMPORT
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';


/// Ce service est responsable de la tâche la plus complexe :
/// charger les portefeuilles bruts et les "hydrater"
/// avec les prix du cache et les taux de change de l'API.
/// C'est une opération asynchrone qui garantit que les données
/// retournées sont complètes.
class PortfolioHydrationService {
  final PortfolioRepository _repository;
  final ApiService _apiService;
  // MODIFIÉ : Le service doit connaître les settings
  SettingsProvider settingsProvider;

  PortfolioHydrationService({
    required PortfolioRepository repository,
    required ApiService apiService,
    required this.settingsProvider, // MODIFIÉ
  })  : _repository = repository,
        _apiService = apiService;

  /// Charge tous les portefeuilles, injecte les transactions,
  /// génère les actifs, et hydrate leurs prix ET taux de change.
  /// L'hydratation se fait vers la DEVISE DU COMPTE.
  Future<List<Portfolio>> getHydratedPortfolios() async {
    debugPrint("🔄 [HydrationService] Début de l'hydratation...");

    // Étape 1: Charger les données de base (Portefeuilles + Transactions + Assets "stupides")
    final portfolios = _repository.getAllPortfolios();

    // Étape 2: Récupérer TOUTES les métadonnées (prix/devise) en une fois
    final allMetadata = _repository.getAllAssetMetadata();

    // Étape 3: Boucle d'hydratation ASYNCHRONE
    List<Future<void>> hydrationTasks = [];

    for (final portfolio in portfolios) {
      for (final inst in portfolio.institutions) {
        for (final acc in inst.accounts) {

          final generatedAssets = acc.assets; // C'est le CHAMP
          final accountCurrency = acc.activeCurrency; // Ex: "EUR"

          final futuresForThisAccount = generatedAssets.map((asset) async {
            final metadata = allMetadata[asset.ticker];

            if (metadata != null) {
              // 3a. Hydrater le prix, la devise du prix, et le rendement
              asset.currentPrice = metadata.currentPrice;
              asset.priceCurrency = metadata.activeCurrency;
              asset.estimatedAnnualYield = metadata.estimatedAnnualYield;

              // 3b. Hydrater le taux de change (ACTIF -> COMPTE)
              // C'est correct, car asset.totalValue sera en devise de COMPTE
              asset.currentExchangeRate = await _apiService.getExchangeRate(
                asset.priceCurrency, // "USD"
                accountCurrency, // "EUR"
              );

            } else {
              // Actif n'ayant pas (encore) de métadonnées
              asset.currentPrice = 0.0;
              asset.priceCurrency = accountCurrency; // Devise du compte par défaut
              asset.currentExchangeRate = 1.0;
            }
          }).toList();

          hydrationTasks.addAll(futuresForThisAccount);
        }
      }
    }

    // Étape 4: Attendre que TOUS les actifs de TOUS les comptes soient hydratés
    try {
      await Future.wait(hydrationTasks);
      debugPrint("✅ [HydrationService] Hydratation terminée.");
    } catch (e) {
      debugPrint("❌ [HydrationService] Erreur durant l'hydratation: $e");
    }

    // Étape 5: Retourner les portefeuilles (avec assets hydratés en devise de COMPTE)
    return portfolios;
  }
}