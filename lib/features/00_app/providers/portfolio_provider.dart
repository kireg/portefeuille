// lib/features/00_app/providers/portfolio_provider.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
// NOUVEAUX IMPORTS POUR LA LOGIQUE EXTERNALISÉE
import 'portfolio_migration_logic.dart';
import 'portfolio_sync_logic.dart';
import 'portfolio_transaction_logic.dart';

class PortfolioProvider extends ChangeNotifier {
  final PortfolioRepository _repository;
  final ApiService _apiService;
  SettingsProvider? _settingsProvider;
  bool _isFirstSettingsUpdate = true;
  final _uuid = const Uuid();

  // Classes de logique
  late final PortfolioMigrationLogic _migrationLogic;
  late final PortfolioSyncLogic _syncLogic;
  late final PortfolioTransactionLogic _transactionLogic;

  // État
  List<Portfolio> _portfolios = [];
  Portfolio? _activePortfolio;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _syncMessage;

  // Getters
  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get activePortfolio => _activePortfolio;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;

  /// Expose toutes les métadonnées pour les écrans de statut (ex: Paramètres)
  Map<String, AssetMetadata> get allMetadata =>
      _repository.getAllAssetMetadata();

  PortfolioProvider({
    required PortfolioRepository repository,
    required ApiService apiService,
  })  : _repository = repository,
        _apiService = apiService {
    // Initialiser les classes de logique
    _migrationLogic = PortfolioMigrationLogic(
      repository: _repository,
      settingsProvider:
          _settingsProvider ?? SettingsProvider(), // Fournit un fallback
      uuid: _uuid,
    );
    _syncLogic = PortfolioSyncLogic(
      repository: _repository,
      apiService: _apiService,
      settingsProvider: _settingsProvider ?? SettingsProvider(),
    );
    _transactionLogic = PortfolioTransactionLogic(
      repository: _repository,
    );

    loadAllPortfolios();
  }

  void updateSettings(SettingsProvider settingsProvider) {
    final bool wasOffline = _settingsProvider?.isOnlineMode ?? false;
    final bool wasNull = _settingsProvider == null;
    _settingsProvider = settingsProvider;
    // Mettre à jour les helpers avec la bonne instance de SettingsProvider
    _migrationLogic.settingsProvider = settingsProvider;
    _syncLogic.settingsProvider = settingsProvider;

    if (_isFirstSettingsUpdate) {
      _isFirstSettingsUpdate = false;
      Future(() async {
        try {
          while (_isLoading) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

          // --- SÉQUENCE DE MIGRATION MISE À JOUR ---
          if (!settingsProvider.migrationV1Done) {
            // 1. Lancer la Migration V1
            await _migrationLogic.runDataMigrationV1(_portfolios);
            // Recharger est crucial après la migration V1
            await loadAllPortfolios();
          }

          if (settingsProvider.migrationV1Done &&
              !settingsProvider.migrationV2Done) {
            // 2. Lancer la Migration V2 (Devises)
            await _migrationLogic.runDataMigrationV2();
            // Recharger est crucial après la migration V2
            await loadAllPortfolios();
          }
          // --- FIN SÉQUENCE ---

          if (_settingsProvider!.isOnlineMode && _activePortfolio != null) {
            await synchroniserLesPrix();
          }
        } catch (e) {
          debugPrint("⚠️ Erreur lors de l'initialisation : $e");
        }
      });
      return;
    }

    if (_settingsProvider!.isOnlineMode &&
        !wasOffline &&
        !wasNull &&
        _activePortfolio != null) {
      synchroniserLesPrix().catchError((e) {
        debugPrint("⚠️ Impossible de synchroniser les prix : $e");
      });
    }
  }

  Future<void> loadAllPortfolios() async {
    _portfolios = _repository.getAllPortfolios();
    if (_portfolios.isNotEmpty) {
      if (_activePortfolio == null) {
        _activePortfolio = _portfolios.first;
      } else {
        try {
          _activePortfolio =
              _portfolios.firstWhere((p) => p.id == _activePortfolio!.id);
        } catch (e) {
          _activePortfolio = _portfolios.isNotEmpty ? _portfolios.first : null;
        }
      }
    } else {
      _activePortfolio = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> forceSynchroniserLesPrix() async {
    if (_activePortfolio == null || _isSyncing) return;
    _isSyncing = true;
    _syncMessage = "Synchronisation forcée en cours...";
    notifyListeners();

    final result = await _syncLogic.forceSynchroniserLesPrix(_activePortfolio!);
    if (result.updatedCount > 0) {
      await loadAllPortfolios();
    }

    _isSyncing = false;
    _syncMessage = result.getSummaryMessage();
    notifyListeners();
  }

  Future<void> synchroniserLesPrix() async {
    if (_activePortfolio == null ||
        _isSyncing ||
        _settingsProvider?.isOnlineMode != true) return;
    _isSyncing = true;
    _syncMessage = "Synchronisation en cours...";
    notifyListeners();

    final result = await _syncLogic.synchroniserLesPrix(_activePortfolio!);
    if (result.updatedCount > 0) {
      await loadAllPortfolios();
    }

    _isSyncing = false;
    _syncMessage = result.getSummaryMessage();
    notifyListeners();
  }

  void clearSyncMessage() {
    _syncMessage = null;
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionLogic.addTransaction(transaction);
    await loadAllPortfolios();
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _transactionLogic.deleteTransaction(transactionId);
    await loadAllPortfolios();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _transactionLogic.updateTransaction(transaction);
    await loadAllPortfolios();
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
    if (_portfolios.any((p) => p.name == "Portefeuille de Démo (2020-2025)")) {
      // MODIFIÉ : Nom du portefeuille de démo V2
      return;
    }
    final demo = _repository.createDemoPortfolio();
    _portfolios.add(demo);
    _activePortfolio = demo;
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
    Portfolio? portfolioToDelete;
    try {
      portfolioToDelete = _portfolios.firstWhere((p) => p.id == portfolioId);
    } catch (e) {
      debugPrint(
          "Impossible de supprimer le portefeuille : ID $portfolioId non trouvé.");
      return;
    }

    final List<Future<void>> deleteFutures = [];
    for (final inst in portfolioToDelete.institutions) {
      for (final acc in inst.accounts) {
        // MODIFIÉ : Utilise acc.transactions (qui a été injecté)
        for (final tx in acc.transactions) {
          deleteFutures.add(_repository.deleteTransaction(tx.id));
        }
      }
    }
    if (deleteFutures.isNotEmpty) {
      await Future.wait(deleteFutures);
    }

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
    // MODIFIÉ : Réinitialise les deux drapeaux
    await _settingsProvider?.setMigrationV1Done();
    await _settingsProvider?.setMigrationV2Done();
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

  Future<void> updateAssetYield(String ticker, double newYield) async {
    final metadata = _repository.getOrCreateAssetMetadata(ticker);
    metadata.updateYield(newYield, isManual: true);
    await _repository.saveAssetMetadata(metadata);
    await loadAllPortfolios();
  }

  Future<void> updateAssetPrice(String ticker, double newPrice,
      {String? currency}) async {
    final metadata = _repository.getOrCreateAssetMetadata(ticker);

    // Déterminer la devise à utiliser :
    // 1. Si une devise est fournie en paramètre, l'utiliser
    // 2. Sinon, utiliser la devise actuelle du metadata
    // 3. Si celle-ci est vide (données legacy), utiliser la devise de base
    final targetCurrency = currency ??
        ((metadata.priceCurrency?.isEmpty ?? true)
            ? _settingsProvider!.baseCurrency
            : metadata.priceCurrency!);

    metadata.updatePrice(newPrice, targetCurrency);
    await _repository.saveAssetMetadata(metadata);
    await loadAllPortfolios();
  }
}
