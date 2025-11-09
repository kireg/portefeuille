// lib/features/00_app/providers/portfolio_provider.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
// --- NOUVEAUX IMPORTS ---
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
// --- FIN NOUVEAUX IMPORTS ---

class PortfolioProvider extends ChangeNotifier {
  final PortfolioRepository _repository;
  // --- NOUVEAU ---
  final ApiService _apiService;
  SettingsProvider? _settingsProvider;
  bool _isFirstSettingsUpdate = true; // Flag pour éviter la sync au premier chargement
  // --- FIN NOUVEAU ---

  List<Portfolio> _portfolios = [];
  Portfolio? _activePortfolio;
  bool _isLoading = true;
  bool _isSyncing = false; // NOUVEAU : Pour l'indicateur de synchronisation

  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get activePortfolio => _activePortfolio;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing; // NOUVEAU

  // --- CONSTRUCTEUR MODIFIÉ ---
  PortfolioProvider({
    required PortfolioRepository repository,
    required ApiService apiService,
  })  : _repository = repository,
        _apiService = apiService {
    loadAllPortfolios();
  }

  // --- NOUVELLE MÉTHODE (pour le ProxyProvider) ---
  /// Met à jour le provider avec la dernière instance de SettingsProvider.
  /// Appelée par le ProxyProvider lorsque les paramètres changent.
  void updateSettings(SettingsProvider settingsProvider) {
    final bool wasOffline = _settingsProvider?.isOnlineMode ?? false;
    final bool wasNull = _settingsProvider == null;
    _settingsProvider = settingsProvider;

    // Ignorer le premier appel (initialisation au démarrage)
    if (_isFirstSettingsUpdate) {
      _isFirstSettingsUpdate = false;
      return;
    }

    // Si l'utilisateur vient d'activer le 'Mode en ligne', on déclenche une synchronisation
    // (mais pas si c'était null avant, ce qui signifie que c'est le premier chargement)
    if (_settingsProvider!.isOnlineMode && !wasOffline && !wasNull) {
      synchroniserLesPrix();
    }
  }

  void loadAllPortfolios() async {
    _portfolios = _repository.getAllPortfolios();
    if (_portfolios.isNotEmpty) {
      _activePortfolio = _portfolios.first;
    }
    _isLoading = false;
    notifyListeners(); // Notifie que le chargement est terminé

    // Synchroniser les prix au démarrage si le mode en ligne est activé
    // Note: synchroniserLesPrix() est maintenant protégé par un try/catch
    // donc l'app ne plantera plus même si le réseau est indisponible
    await Future.delayed(Duration.zero);
    if (_settingsProvider?.isOnlineMode == true) {
      await synchroniserLesPrix();
    }
  }

  // --- NOUVELLE MÉTHODE (Logique de synchronisation) ---
  Future<void> synchroniserLesPrix() async {
    if (_activePortfolio == null) return;
    if (_isSyncing) return; // Ne pas synchroniser si déjà en cours
    if (_settingsProvider?.isOnlineMode != true) return; // Vérifie le mode en ligne

    _isSyncing = true;
    notifyListeners(); // Notifie l'UI que la synchronisation *commence*

    try {
      bool hasChanges = false;
      final portfolioToSync = _activePortfolio!;

      // 1. Collecter tous les actifs
      List<Asset> allAssets = [];
      for (var inst in portfolioToSync.institutions) {
        for (var acc in inst.accounts) {
          allAssets.addAll(acc.assets);
        }
      }

      // 2. Obtenir les tickers uniques (et non vides)
      final tickers =
      allAssets.map((a) => a.ticker).where((t) => t.isNotEmpty).toSet();
      if (tickers.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return;
      }

      // 3. Récupérer les prix (en parallèle)
      Map<String, double?> prices = {};
      await Future.wait(tickers.map((ticker) async {
        final price = await _apiService.getPrice(ticker);
        if (price != null) {
          prices[ticker] = price;
        }
      }));

      // 4. Appliquer les nouveaux prix
      for (var asset in allAssets) {
        if (prices.containsKey(asset.ticker)) {
          final newPrice = prices[asset.ticker]!;
          // Optimisation : ne mettre à jour que si le prix a changé
          if (asset.currentPrice != newPrice) {
            asset.currentPrice = newPrice;
            hasChanges = true;
          }
        }
      }

      // 5. Sauvegarder et notifier si des changements ont eu lieu
      if (hasChanges) {
        updateActivePortfolio(); // Cette méthode notifie déjà les listeners
      } else {
        notifyListeners(); // Notifie que la synchronisation *est terminée* (même sans changements)
      }
    } catch (e) {
      // Capturer TOUTES les exceptions (réseau, DNS, timeout, etc.)
      // pour éviter que l'app ne plante au démarrage
      debugPrint("⚠️ Erreur lors de la synchronisation des prix : $e");
      // L'utilisateur verra simplement que la sync n'a pas fonctionné
    } finally {
      // Toujours réinitialiser l'état de synchronisation
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
    notifyListeners();
  }

  void addNewPortfolio(String name) {
    final newPortfolio = _repository.createEmptyPortfolio(name);
    _portfolios.add(newPortfolio);
    _activePortfolio = newPortfolio;
    notifyListeners();
  }

  void savePortfolio(Portfolio portfolio) {
    // Met à jour l'objet dans la liste en mémoire
    int index = _portfolios.indexWhere((p) => p.id == portfolio.id);
    if (index != -1) {
      _portfolios[index] = portfolio;
    } else {
      _portfolios.add(portfolio); // Sécurité
    }

    // Met à jour l'objet actif s'il s'agit de celui-ci
    if (_activePortfolio?.id == portfolio.id) {
      _activePortfolio = portfolio;
    }

    _repository.savePortfolio(portfolio); // Sauvegarde sur le disque
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

  void addAsset(String accountId, Asset newAsset) {
    if (_activePortfolio == null) return;
    final updatedPortfolio = _activePortfolio!.deepCopy();
    try {
      for (var inst in updatedPortfolio.institutions) {
        for (var acc in inst.accounts) {
          if (acc.id == accountId) {
            acc.assets.add(newAsset);
            savePortfolio(updatedPortfolio);
            return;
          }
        }
      }
      debugPrint("Compte non trouvé : $accountId");
    } catch (e) {
      debugPrint("Erreur lors de l'ajout de l'actif : $e");
    }
  }

  // ========== GESTION DES PLANS D'ÉPARGNE ==========

  /// Ajoute un nouveau plan d'épargne au portefeuille actif
  void addSavingsPlan(SavingsPlan newPlan) {
    if (_activePortfolio == null) return;

    // 1. Créer une copie immuable du portefeuille
    final updatedPortfolio = _activePortfolio!.deepCopy();

    // 2. Ajouter le plan à la copie
    updatedPortfolio.savingsPlans.add(newPlan);

    // 3. Sauvegarder (notifie automatiquement les listeners)
    savePortfolio(updatedPortfolio);
  }

  /// Met à jour un plan d'épargne existant
  void updateSavingsPlan(String planId, SavingsPlan updatedPlan) {
    if (_activePortfolio == null) return;

    // 1. Créer une copie immuable
    final updatedPortfolio = _activePortfolio!.deepCopy();

    // 2. Trouver et remplacer le plan
    final index = updatedPortfolio.savingsPlans.indexWhere((p) => p.id == planId);
    if (index != -1) {
      updatedPortfolio.savingsPlans[index] = updatedPlan;
      savePortfolio(updatedPortfolio);
    } else {
      debugPrint("Plan d'épargne non trouvé : $planId");
    }
  }

  /// Supprime un plan d'épargne
  void deleteSavingsPlan(String planId) {
    if (_activePortfolio == null) return;

    // 1. Créer une copie immuable
    final updatedPortfolio = _activePortfolio!.deepCopy();

    // 2. Retirer le plan de la copie
    updatedPortfolio.savingsPlans.removeWhere((p) => p.id == planId);

    // 3. Sauvegarder
    savePortfolio(updatedPortfolio);
  }
}
