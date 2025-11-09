// lib/features/00_app/providers/portfolio_provider.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

// --- NOUVEAUX IMPORTS MIGRATION ---
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:uuid/uuid.dart';
// --- FIN NOUVEAUX IMPORTS ---

class PortfolioProvider extends ChangeNotifier {
  final PortfolioRepository _repository;
  final ApiService _apiService;
  SettingsProvider? _settingsProvider;
  bool _isFirstSettingsUpdate = true;

  // NOUVEAU : Pour générer les ID de migration
  final _uuid = const Uuid();

  List<Portfolio> _portfolios = [];
  Portfolio? _activePortfolio;
  bool _isLoading = true;
  bool _isSyncing = false;
  
  // NOUVEAU : Timestamp pour forcer le rebuild des widgets
  int _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;

  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get activePortfolio => _activePortfolio;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  int get lastUpdateTimestamp => _lastUpdateTimestamp; // Getter pour le timestamp

  PortfolioProvider({
    required PortfolioRepository repository,
    required ApiService apiService,
  })  : _repository = repository,
        _apiService = apiService {
    // Charge les portefeuilles IMMÉDIATEMENT
    // (ils peuvent contenir des données "stale")
    loadAllPortfolios();
  }

  /// Met à jour le provider avec la dernière instance de SettingsProvider.
  /// Appelée par le ProxyProvider lorsque les paramètres changent.
  void updateSettings(SettingsProvider settingsProvider) {
    final bool wasOffline = _settingsProvider?.isOnlineMode ?? false;
    final bool wasNull = _settingsProvider == null;
    _settingsProvider = settingsProvider;

    // --- MODIFICATION MAJEURE : GESTION DE LA MIGRATION ---
    if (_isFirstSettingsUpdate) {
      _isFirstSettingsUpdate = false;

      // 1. VÉRIFIER ET LANCER LA MIGRATION
      // Doit être 'async' mais la méthode update ne peut pas l'être,
      // donc on utilise un Future anonyme avec gestion d'erreur.
      Future(() async {
        try {
          // 1a. Attendre que les portfolios soient chargés
          while (_isLoading) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          
          if (!settingsProvider.migrationV1Done) {
            await _runDataMigrationV1(settingsProvider);
          }

          // 2. DÉCLENCHER LA SYNCHRO (après migration potentielle)
          // Vérifier que le portfolio est chargé avant de synchroniser
          if (_settingsProvider!.isOnlineMode && _activePortfolio != null) {
            await synchroniserLesPrix();
          }
        } catch (e) {
          debugPrint("⚠️ Erreur lors de l'initialisation : $e");
          // L'application continue de fonctionner même en cas d'erreur réseau
        }
      });

      return; // Fin de la logique du premier chargement
    }
    // --- FIN MODIFICATION ---

    // Logique de synchro (si l'utilisateur active/désactive le mode en ligne)
    if (_settingsProvider!.isOnlineMode && !wasOffline && !wasNull && _activePortfolio != null) {
      // Note : La synchro automatique peut échouer si aucune connexion Internet
      // L'utilisateur peut toujours la déclencher manuellement via le bouton
      synchroniserLesPrix().catchError((e) {
        debugPrint("⚠️ Impossible de synchroniser les prix : $e");
      });
    }
  }

  /// Charge tous les portefeuilles (potentiellement avec des données périmées)
  Future<void> loadAllPortfolios() async {
    _portfolios = _repository.getAllPortfolios();
    if (_portfolios.isNotEmpty) {
      _activePortfolio = _portfolios.first;
    }
    _isLoading = false;
    notifyListeners();
    // La synchronisation des prix est déplacée dans updateSettings
    // pour s'assurer qu'elle s'exécute APRÈS la migration.
  }

  /// Ajoute une transaction et recharge les données.
  Future<void> addTransaction(Transaction transaction) async {
    // 1. Sauvegarder la nouvelle transaction
    await _repository.saveTransaction(transaction);

    // 2. Recharger les portefeuilles
    // Cela force la ré-injection des transactions (via getAllPortfolios)
    // et le recalcul des getters.
    await loadAllPortfolios();

    // 3. Notifier (déjà fait par loadAllPortfolios)
  }

  // --- NOUVELLE MÉTHODE ---
  /// Supprime une transaction et recharge les données.
  Future<void> deleteTransaction(String transactionId) async {
    // 1. Supprimer la transaction
    await _repository.deleteTransaction(transactionId);
    // 2. Recharger les portefeuilles pour recalculer les soldes
    await loadAllPortfolios();
  }

  /// Met à jour une transaction existante et recharge les données.
  Future<void> updateTransaction(Transaction transaction) async {
    // 1. Sauvegarder la transaction (put écrase l'existant avec le même ID)
    await _repository.saveTransaction(transaction);
    // 2. Recharger les portefeuilles
    await loadAllPortfolios();
  }

  // --- NOUVELLE MÉTHODE DE MIGRATION ---
  /// Convertit les champs `stale_` en transactions.
  Future<void> _runDataMigrationV1(SettingsProvider settingsProvider) async {
    // Vérifie s'il y a des données à migrer
    final bool needsMigration = _portfolios.any((p) => p.institutions
        .any((i) => i.accounts.any((a) =>
    a.stale_cashBalance != null || (a.stale_assets?.isNotEmpty ?? false))));

    if (!needsMigration) {
      debugPrint("Migration V1 : Aucune donnée périmée trouvée. Ignoré.");
      await settingsProvider.setMigrationV1Done();
      return;
    }

    debugPrint("--- DÉBUT MIGRATION V1 ---");
    final List<Transaction> newTransactions = [];

    for (final portfolio in _portfolios) {
      bool portfolioNeedsSave = false;
      for (final inst in portfolio.institutions) {
        for (final acc in inst.accounts) {
          // Date fictive pour les transactions migrées
          // MODIFICATION : Utiliser une date antérieure pour ne pas perturber l'historique récent
          final migrationDate = DateTime(2020, 1, 1);

          // Variables pour gérer le solde total
          double totalCashFromAssets = 0.0;

          // 1. D'abord, calculer le total de cash nécessaire pour les actifs
          if (acc.stale_assets != null && acc.stale_assets!.isNotEmpty) {
            for (final asset in acc.stale_assets!) {
              final qty = asset.stale_quantity;
              final pru = asset.stale_averagePrice;
              if (qty != null && pru != null && qty > 0) {
                totalCashFromAssets += (qty * pru);
              }
            }
          }

          // 2. Migrer les liquidités (stale_cashBalance)
          // MODIFICATION : Créer UN SEUL dépôt pour le solde initial + coût des actifs
          final totalCashNeeded = (acc.stale_cashBalance ?? 0.0) + totalCashFromAssets;
          
          if (totalCashNeeded > 0) {
            debugPrint(
                "Migration : Ajout Dépôt initial de ${totalCashNeeded.toStringAsFixed(2)}€ pour ${acc.name} "
                "(Liquidités: ${acc.stale_cashBalance?.toStringAsFixed(2) ?? '0.00'}€ + Actifs: ${totalCashFromAssets.toStringAsFixed(2)}€)");
            
            newTransactions.add(Transaction(
              id: _uuid.v4(),
              accountId: acc.id,
              type: TransactionType.Deposit,
              date: migrationDate,
              amount: totalCashNeeded,
              notes: "Migration v1 - Dépôt initial (Solde: ${acc.stale_cashBalance?.toStringAsFixed(2) ?? '0.00'}€)",
            ));
            acc.stale_cashBalance = null; // Nettoyer
            portfolioNeedsSave = true;
          }

          // 3. Migrer les actifs (stale_assets)
          if (acc.stale_assets != null && acc.stale_assets!.isNotEmpty) {
            debugPrint(
                "Migration : ${acc.stale_assets!.length} actifs pour ${acc.name}");

            for (final asset in acc.stale_assets!) {
              // Lire les données périmées de l'asset
              final qty = asset.stale_quantity;
              final pru = asset.stale_averagePrice;

              if (qty != null && pru != null && qty > 0) {
                final totalCost = qty * pru;
                debugPrint(
                    "Migration : Actif ${asset.ticker} (Qty: $qty, PRU: ${pru.toStringAsFixed(2)}€, Type: ${asset.type.displayName})");

                // Étape 3a: Achat de l'actif (impact cash négatif)
                // MODIFICATION : Utiliser le type d'actif existant
                newTransactions.add(Transaction(
                  id: _uuid.v4(),
                  accountId: acc.id,
                  type: TransactionType.Buy,
                  date: migrationDate,
                  assetTicker: asset.ticker,
                  assetName: asset.name,
                  assetType: asset.type, // <--- NOUVEAU : Préservation du type
                  quantity: qty,
                  price: pru,
                  amount: -totalCost,
                  fees: 0,
                  notes: "Migration v1 - Achat ${asset.ticker}",
                ));
              }
            }
            acc.stale_assets = null; // Nettoyer
            portfolioNeedsSave = true;
          }
        }
      }

      // 3. Sauvegarder le portefeuille "nettoyé" (champs stale_ à null)
      if (portfolioNeedsSave) {
        debugPrint("Migration : Nettoyage du portefeuille ${portfolio.name}");
        await _repository.savePortfolio(portfolio);
      }
    }

    // 4. Sauvegarder TOUTES les nouvelles transactions en une fois
    debugPrint("Migration : Sauvegarde de ${newTransactions.length} transactions...");
    for (final tx in newTransactions) {
      await _repository.saveTransaction(tx);
    }

    // 5. Marquer la migration comme terminée
    await settingsProvider.setMigrationV1Done();

    // 6. Recharger les données (Portfolio + Transactions injectées)
    debugPrint("--- FIN MIGRATION V1 : Rechargement des données ---");
    await loadAllPortfolios();
  }
  // --- FIN NOUVELLE MÉTHODE ---


  // --- Le reste du fichier (synchroniserLesPrix, addDemoPortfolio, etc.) reste identique ---
  // ... (Collez le reste du fichier PortfolioProvider à partir d'ici) ...

  Future<void> synchroniserLesPrix() async {
    if (_activePortfolio == null) return;
    if (_isSyncing) return;
    if (_settingsProvider?.isOnlineMode != true) return;

    _isSyncing = true;
    notifyListeners();

    try {
      bool hasChanges = false;
      final portfolioToSync = _activePortfolio!;

      // 1. Collecter tous les actifs (MAJ : utilise le getter)
      List<Asset> allAssets = [];
      for (var inst in portfolioToSync.institutions) {
        for (var acc in inst.accounts) {
          // NOTE : 'assets' est maintenant un getter qui sera vide
          // car la logique n'est pas implémentée.
          // La synchro ne fonctionnera qu'après l'implémentation des getters.
          allAssets.addAll(acc.assets);
        }
      }

      final tickers =
      allAssets.map((a) => a.ticker).where((t) => t.isNotEmpty).toSet();
      if (tickers.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return;
      }

      // 2. Récupérer les prix avec gestion d'erreur individuelle
      Map<String, double?> prices = {};
      await Future.wait(
        tickers.map((ticker) async {
          try {
            final price = await _apiService.getPrice(ticker);
            if (price != null) {
              prices[ticker] = price;
            }
          } catch (e) {
            debugPrint("⚠️ Impossible de récupérer le prix pour $ticker : $e");
            // Continue avec les autres tickers
          }
        }),
        eagerError: false, // Continue même si un Future échoue
      );
      
      // 3. Mettre à jour les métadonnées des actifs
      for (var ticker in prices.keys) {
        final newPrice = prices[ticker];
        if (newPrice != null) {
          final metadata = _repository.getOrCreateAssetMetadata(ticker);
          if (metadata.currentPrice != newPrice) {
            metadata.updatePrice(newPrice);
            await _repository.saveAssetMetadata(metadata);
            hasChanges = true;
          }
        }
      }

      if (hasChanges) {
        // Recharger les portfolios pour injecter les nouvelles métadonnées
        await loadAllPortfolios();
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint("⚠️ Erreur lors de la synchronisation des prix : $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void setActivePortfolio(String portfolioId) {
    try {
      _activePortfolio = _portfolios.firstWhere((p) => p.id == portfolioId);
      notifyListeners();
    } catch (e) {
      debugPrint("Portefeuille non trouvé : $portfolioId");
    }
  }

  void addDemoPortfolio() {
    if (_portfolios.any((p) => p.name == "Portefeuille de Démo")) {
      return;
    }
    final demo = _repository.createDemoPortfolio();
    _portfolios.add(demo);
    _activePortfolio = demo;

    // MODIFIÉ : Recharger pour hydrater les transactions de démo
    loadAllPortfolios();
  }

  void addNewPortfolio(String name) {
    final newPortfolio = _repository.createEmptyPortfolio(name);
    _portfolios.add(newPortfolio);
    _activePortfolio = newPortfolio;
    notifyListeners();
  }

  void savePortfolio(Portfolio portfolio) {
    int index = _portfolios.indexWhere((p) => p.id == portfolio.id);
    if (index != -1) {
      _portfolios[index] = portfolio;
    } else {
      _portfolios.add(portfolio);
    }
    if (_activePortfolio?.id == portfolio.id) {
      _activePortfolio = portfolio;
    }
    _repository.savePortfolio(portfolio);
    notifyListeners();
  }

  void updateActivePortfolio() {
    if (_activePortfolio == null) return;
    _repository.savePortfolio(_activePortfolio!);
    notifyListeners();
  }

  void renameActivePortfolio(String newName) {
    if (_activePortfolio == null) return;
    _activePortfolio!.name = newName;
    updateActivePortfolio();
  }

  Future<void> deletePortfolio(String portfolioId) async {
    // TODO: Il faudra aussi supprimer les transactions liées à ce portefeuille
    await _repository.deletePortfolio(portfolioId);
    _portfolios.removeWhere((p) => p.id == portfolioId);
    if (_activePortfolio?.id == portfolioId) {
      _activePortfolio = _portfolios.isNotEmpty ? _portfolios.first : null;
    }
    notifyListeners();
  }

  Future<void> resetAllData() async {
    await _repository.deleteAllData();
    _portfolios = [];
    _activePortfolio = null;

    // NOUVEAU : Réinitialiser aussi le drapeau de migration
    await _settingsProvider?.setMigrationV1Done(); // Marque comme fait (car vide)

    notifyListeners();
  }

  void addInstitution(Institution newInstitution) {
    if (_activePortfolio == null) return;
    final updatedPortfolio = _activePortfolio!.deepCopy();
    updatedPortfolio.institutions.add(newInstitution);
    savePortfolio(updatedPortfolio);
  }

  void addAccount(String institutionId, Account newAccount) {
    if (_activePortfolio == null) return;
    final updatedPortfolio = _activePortfolio!.deepCopy();
    try {
      updatedPortfolio.institutions
          .firstWhere((inst) => inst.id == institutionId)
          .accounts
          .add(newAccount);
      savePortfolio(updatedPortfolio);
    } catch (e) {
      debugPrint("Institution non trouvée : $institutionId");
    }
  }

  // CETTE MÉTHODE EST MAINTENANT OBSOLÈTE
  // L'ajout d'asset se fera via une TRANSACTION
  void addAsset(String accountId, Asset newAsset) {
    /*
    if (_activePortfolio == null) return;
    final updatedPortfolio = _activePortfolio!.deepCopy();
    try {
      for (var inst in updatedPortfolio.institutions) {
        for (var acc in inst.accounts) {
          if (acc.id == accountId) {
            // ERREUR : acc.assets est un getter
            // acc.assets.add(newAsset);
            savePortfolio(updatedPortfolio);
            return;
          }
        }
      }
      debugPrint("Compte non trouvé : $accountId");
    } catch (e) {
      debugPrint("Erreur lors de l'ajout de l'actif : $e");
    }
    */
  }

  // ========== GESTION DES PLANS D'ÉPARGNE ==========

  void addSavingsPlan(SavingsPlan newPlan) {
    if (_activePortfolio == null) return;
    final updatedPortfolio = _activePortfolio!.deepCopy();
    updatedPortfolio.savingsPlans.add(newPlan);
    savePortfolio(updatedPortfolio);
  }

  void updateSavingsPlan(String planId, SavingsPlan updatedPlan) {
    if (_activePortfolio == null) return;
    final updatedPortfolio = _activePortfolio!.deepCopy();
    final index =
    updatedPortfolio.savingsPlans.indexWhere((p) => p.id == planId);
    if (index != -1) {
      updatedPortfolio.savingsPlans[index] = updatedPlan;
      savePortfolio(updatedPortfolio);
    } else {
      debugPrint("Plan d'épargne non trouvé : $planId");
    }
  }

  void deleteSavingsPlan(String planId) {
    if (_activePortfolio == null) return;
    final updatedPortfolio = _activePortfolio!.deepCopy();
    updatedPortfolio.savingsPlans.removeWhere((p) => p.id == planId);
    savePortfolio(updatedPortfolio);
  }

  // ========== GESTION DES MÉTADONNÉES D'ACTIFS ==========

  /// Met à jour le rendement annuel estimé d'un actif.
  /// Sauvegarde dans AssetMetadata et recharge les portfolios.
  Future<void> updateAssetYield(String ticker, double newYield) async {
    final metadata = _repository.getOrCreateAssetMetadata(ticker);
    metadata.updateYield(newYield, isManual: true);
    await _repository.saveAssetMetadata(metadata);
    
    // Recharger les portfolios pour injecter les nouvelles métadonnées
    await loadAllPortfolios();
    
    _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  /// Met à jour le prix actuel d'un actif.
  /// Sauvegarde dans AssetMetadata et recharge les portfolios.
  Future<void> updateAssetPrice(String ticker, double newPrice) async {
    final metadata = _repository.getOrCreateAssetMetadata(ticker);
    metadata.updatePrice(newPrice);
    await _repository.saveAssetMetadata(metadata);
    
    // Recharger les portfolios pour injecter les nouvelles métadonnées
    await loadAllPortfolios();
    
    _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }
}