import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
// import 'package:uuid/uuid.dart'; // SUPPRIMÉ (Avertissement 2)

class PortfolioProvider extends ChangeNotifier {
  final PortfolioRepository _repository;
  // final _uuid = const Uuid(); // SUPPRIMÉ (Avertissement 2)

  List<Portfolio> _portfolios = [];
  Portfolio? _activePortfolio;
  bool _isLoading = true;

  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get activePortfolio => _activePortfolio;
  bool get isLoading => _isLoading;

  PortfolioProvider({required PortfolioRepository repository})
      : _repository = repository {
    loadAllPortfolios();
  }

  void loadAllPortfolios() {
    _portfolios = _repository.getAllPortfolios();
    if (_portfolios.isNotEmpty) {
      _activePortfolio = _portfolios.first;
    }
    _isLoading = false;
    notifyListeners();
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

  /// NOUVELLE MÉTHODE (pour corriger l'Erreur 3)
  /// Sauvegarde un portefeuille (généralement après une édition).
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

  /// Met à jour le portefeuille actif (après modif interne) et sauvegarde.
  void updateActivePortfolio() {
    if (_activePortfolio == null) return;
    _repository.savePortfolio(_activePortfolio!);
    notifyListeners();
  }

  void renameActivePortfolio(String newName) {
    if (_activePortfolio == null) return;

    // 1. Modifier le nom sur l'objet en mémoire
    _activePortfolio!.name = newName;

    // 2. Sauvegarder et notifier
    // (updateActivePortfolio fait déjà les deux)
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

    // 1. Créer une copie immuable
    final updatedPortfolio = _activePortfolio!.deepCopy();

    // 2. Modifier la copie
    updatedPortfolio.institutions.add(newInstitution);

    // 3. Sauvegarder la nouvelle instance (ceci remplacera l'ancienne)
    // C'est la fonction savePortfolio qui notifie les listeners.
    savePortfolio(updatedPortfolio);
  }

  void addAccount(String institutionId, Account newAccount) {
    if (_activePortfolio == null) return;

    // 1. Créer une copie immuable
    final updatedPortfolio = _activePortfolio!.deepCopy();

    // 2. Modifier la copie
    try {
      updatedPortfolio.institutions
          .firstWhere((inst) => inst.id == institutionId)
          .accounts
          .add(newAccount);

      // 3. Sauvegarder la nouvelle instance
      savePortfolio(updatedPortfolio);
    } catch (e) {
      debugPrint("Institution non trouvée : $institutionId");
    }
  }

  void addAsset(String accountId, Asset newAsset) {
    if (_activePortfolio == null) return;

    // 1. Créer une copie immuable
    final updatedPortfolio = _activePortfolio!.deepCopy();

    // 2. Modifier la copie
    try {
      for (var inst in updatedPortfolio.institutions) {
        for (var acc in inst.accounts) {
          if (acc.id == accountId) {
            acc.assets.add(newAsset);

            // 3. Sauvegarder la nouvelle instance
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
