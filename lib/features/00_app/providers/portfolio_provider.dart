// lib/features/00_app/providers/portfolio_provider.dart
// REMPLACEZ L'INTÉGRALITÉ DU FICHIER (version finale)

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/projection_data.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';
// ... (autres imports)
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'portfolio_migration_logic.dart';
import 'portfolio_sync_logic.dart';
import 'portfolio_transaction_logic.dart';
import 'portfolio_hydration_service.dart';
import 'demo_data_service.dart';

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
  late final PortfolioHydrationService _hydrationService;
  late final DemoDataService _demoDataService;

  // État
  List<Portfolio> _portfolios = [];
  Portfolio? _activePortfolio;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _syncMessage;

  // -----------------------------------------------------------------
  // ▼▼▼ NOUVEL ÉTAT POUR LES VALEURS CONVERTIES ▼▼▼
  // -----------------------------------------------------------------

  /// La devise de base actuellement utilisée pour les calculs ci-dessous.
  String _currentBaseCurrency = 'EUR';

  /// La valeur totale du portefeuille, convertie dans la _currentBaseCurrency.
  double _convertedTotalValue = 0.0;

  /// La P/L totale du portefeuille, convertie dans la _currentBaseCurrency.
  double _convertedTotalPL = 0.0;

  /// Le capital investi total, converti dans la _currentBaseCurrency.
  double _convertedTotalInvested = 0.0;

  /// Map [accountId] -> Valeur totale convertie (pour les widgets enfants)
  Map<String, double> _convertedAccountValues = {};

  /// Map [accountId] -> P/L convertie (pour les widgets enfants)
  Map<String, double> _convertedAccountPLs = {};

  /// Map [accountId] -> Capital investi converti
  Map<String, double> _convertedAccountInvested = {};

  // -----------------------------------------------------------------
  // ▲▲▲ FIN NOUVEL ÉTAT ▲▲▲
  // -----------------------------------------------------------------


  // Getters
  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get activePortfolio => _activePortfolio;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;
  Map<String, AssetMetadata> get allMetadata =>
      _repository.getAllAssetMetadata();

  // -----------------------------------------------------------------
  // ▼▼▼ NOUVEAUX GETTERS POUR L'INTERFACE ▼▼▼
  // -----------------------------------------------------------------

  /// La devise de base active (ex: "USD")
  String get currentBaseCurrency => _currentBaseCurrency;

  /// La valeur totale convertie (ex: 10800.0)
  double get activePortfolioTotalValue => _convertedTotalValue;

  /// La P/L totale convertie
  double get activePortfolioTotalPL => _convertedTotalPL;

  /// Le % de P/L (calculé à partir des valeurs converties)
  double get activePortfolioTotalPLPercentage {
    if (_convertedTotalInvested == 0.0) return 0.0;
    return _convertedTotalPL / _convertedTotalInvested;
  }

  /// Le rendement annuel (on garde celui du portfolio, c'est un %)
  double get activePortfolioEstimatedAnnualYield =>
      _activePortfolio?.estimatedAnnualYield ?? 0.0;

  /// Récupère la valeur convertie pour un compte spécifique
  double getConvertedAccountValue(String accountId) =>
      _convertedAccountValues[accountId] ?? 0.0;

  /// Récupère la P/L convertie pour un compte spécifique
  double getConvertedAccountPL(String accountId) =>
      _convertedAccountPLs[accountId] ?? 0.0;

  /// Récupère le capital investi converti pour un compte spécifique
  double getConvertedAccountInvested(String accountId) =>
      _convertedAccountInvested[accountId] ?? 0.0;

  // -----------------------------------------------------------------
  // ▲▲▲ FIN NOUVEAUX GETTERS ▲▲▲
  // -----------------------------------------------------------------

  PortfolioProvider({
    required PortfolioRepository repository,
    required ApiService apiService,
  })  : _repository = repository,
        _apiService = apiService {
    // Initialiser les classes de logique
    _migrationLogic = PortfolioMigrationLogic(
      repository: _repository,
      settingsProvider: _settingsProvider ?? SettingsProvider(),
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
    // ▼▼▼ CORRECTION CI-DESSOUS ▼▼▼
    _hydrationService = PortfolioHydrationService(
      repository: _repository,
      apiService: _apiService,
      // AJOUTEZ CETTE LIGNE :
      settingsProvider: _settingsProvider ?? SettingsProvider(),
    );
    // ▲▲▲ FIN CORRECTION ▲▲▲
    _demoDataService = DemoDataService(
      repository: _repository,
    );

    loadAllPortfolios();
  }

  // -----------------------------------------------------------------
  // ▼▼▼ NOUVELLE MÉTHODE DE CALCUL ▼▼▼
  // -----------------------------------------------------------------

  /// Recalcule toutes les valeurs totales en les convertissant
  /// vers la devise de base de l'utilisateur.
  Future<void> _recalculateConvertedTotals() async {
    if (_activePortfolio == null || _settingsProvider == null) {
      _convertedTotalValue = 0.0;
      _convertedTotalPL = 0.0;
      _convertedTotalInvested = 0.0;
      _convertedAccountValues = {};
      _convertedAccountPLs = {};
      _convertedAccountInvested = {};
      _currentBaseCurrency = _settingsProvider?.baseCurrency ?? 'EUR';
      // Pas de notifyListeners() ici, sera fait par la méthode appelante
      return;
    }

    final targetCurrency = _settingsProvider!.baseCurrency;

    // 1. Collecter toutes les devises de compte uniques
    final Set<String> accountCurrencies = _activePortfolio!.institutions
        .expand((inst) => inst.accounts)
        .map((acc) => acc.activeCurrency)
        .toSet();

    // 2. Récupérer tous les taux de change nécessaires en parallèle
    final Map<String, double> rates = {};
    final futures = accountCurrencies.map((accountCurrency) async {
      if (accountCurrency == targetCurrency) {
        rates[accountCurrency] = 1.0;
        return;
      }
      rates[accountCurrency] =
      await _apiService.getExchangeRate(accountCurrency, targetCurrency);
    });

    // Attendre que tous les appels API soient terminés
    await Future.wait(futures);

    // 3. Calculer les totaux (rapide, sans await)
    double newTotalValue = 0.0;
    double newTotalPL = 0.0;
    double newTotalInvested = 0.0;
    Map<String, double> newAccountValues = {};
    Map<String, double> newAccountPLs = {};
    Map<String, double> newAccountInvested = {};

    for (final inst in _activePortfolio!.institutions) {
      for (final acc in inst.accounts) {
        // Récupérer le taux pour la devise de ce compte
        final rate = rates[acc.activeCurrency] ?? 1.0;

        // Les getters du modèle (acc.totalValue) sont en devise de COMPTE
        final accValue = acc.totalValue * rate;
        final accPL = acc.profitAndLoss * rate;
        final accInvested = acc.totalInvestedCapital * rate;

        // Mettre à jour les totaux globaux
        newTotalValue += accValue;
        newTotalPL += accPL;
        newTotalInvested += accInvested;

        // Stocker les valeurs par compte pour les widgets enfants
        newAccountValues[acc.id] = accValue;
        newAccountPLs[acc.id] = accPL;
        newAccountInvested[acc.id] = accInvested;
      }
    }

    // 4. Mettre à jour l'état du provider
    _convertedTotalValue = newTotalValue;
    _convertedTotalPL = newTotalPL;
    _convertedTotalInvested = newTotalInvested;
    _convertedAccountValues = newAccountValues;
    _convertedAccountPLs = newAccountPLs;
    _convertedAccountInvested = newAccountInvested;
    _currentBaseCurrency = targetCurrency;

    // notifyListeners() sera appelé par _refreshData ou loadAllPortfolios
  }
  // -----------------------------------------------------------------
  // ▲▲▲ FIN NOUVELLE MÉTHODE ▲▲▲
  // -----------------------------------------------------------------

  void updateSettings(SettingsProvider settingsProvider) {
    final bool wasOffline = _settingsProvider?.isOnlineMode ?? false;
    final bool wasNull = _settingsProvider == null;

    // ▼▼▼ MODIFIÉ : Détecter le changement de devise ▼▼▼
    final bool currencyChanged = (_settingsProvider != null &&
        _settingsProvider!.baseCurrency != settingsProvider.baseCurrency);
    // ▲▲▲ FIN MODIFICATION ▲▲▲

    _settingsProvider = settingsProvider;

    _migrationLogic.settingsProvider = settingsProvider;
    _syncLogic.settingsProvider = settingsProvider;
    // Passez le provider mis à jour à l'hydration service
    _hydrationService.settingsProvider = settingsProvider;

    // ▼▼▼ MODIFIÉ : Recalculer si la devise change ▼▼▼
    if (currencyChanged && !_isLoading) {
      debugPrint("Devise de base modifiée. Recalcul des totaux...");
      _refreshData(); // _refreshData appelle _recalculateConvertedTotals
    }
    // ▲▲▲ FIN MODIFICATION ▲▲▲

    if (_isFirstSettingsUpdate) {
      _isFirstSettingsUpdate = false;
      Future(() async {
        try {
          while (_isLoading) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

          bool needsReload = false;
          if (!settingsProvider.migrationV1Done) {
            await _migrationLogic.runDataMigrationV1(_portfolios);
            needsReload = true;
          }

          if (settingsProvider.migrationV1Done &&
              !settingsProvider.migrationV2Done) {
            await _migrationLogic.runDataMigrationV2();
            needsReload = true;
          }

          if (needsReload) {
            await _refreshData();
          }

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

  // ▼▼▼ MODIFIÉ : _refreshData appelle maintenant _recalculateConvertedTotals ▼▼▼
  Future<void> _refreshData() async {
    // 1. Recharge les données (Transactions -> Assets "stupides")
    // 2. Hydrate les assets (Assets "stupides" -> Assets hydratés en devise de COMPTE)
    _portfolios = await _hydrationService.getHydratedPortfolios();

    // ... (logique de sélection de _activePortfolio inchangée)
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

    // 3. Calcule les totaux convertis en devise de BASE
    await _recalculateConvertedTotals();

    // 4. Notifie l'interface
    notifyListeners();
  }

  // ▼▼▼ MODIFIÉ : loadAllPortfolios appelle _recalculateConvertedTotals ▼▼▼
  Future<void> loadAllPortfolios() async {
    _isLoading = true;
    notifyListeners();

    if (_settingsProvider != null) {
      if (!_settingsProvider!.migrationV1Done) {
        await _migrationLogic.runDataMigrationV1(_portfolios);
      }
      if (_settingsProvider!.migrationV1Done &&
          !_settingsProvider!.migrationV2Done) {
        await _migrationLogic.runDataMigrationV2();
      }
    }

    // 1. Charge et hydrate les données en devise de COMPTE
    _portfolios = await _hydrationService.getHydratedPortfolios();

    // ... (logique de sélection de _activePortfolio inchangée)
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

    // 2. Calcule les totaux convertis en devise de BASE
    await _recalculateConvertedTotals();

    _isLoading = false;
    notifyListeners(); // Notifie l'UI que le chargement est terminé
  }

  // ... (forceSynchroniserLesPrix et synchroniserLesPrix appellent déjà _refreshData) ...
  Future<void> forceSynchroniserLesPrix() async {
    if (_activePortfolio == null || _isSyncing) return;
    _isSyncing = true;
    _syncMessage = "Synchronisation forcée en cours...";
    notifyListeners();

    final result = await _syncLogic.forceSynchroniserLesPrix(_activePortfolio!);
    if (result.updatedCount > 0) {
      await _refreshData(); // _refreshData va recalculer les totaux
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
      await _refreshData(); // _refreshData va recalculer les totaux
    }

    _isSyncing = false;
    _syncMessage = result.getSummaryMessage();
    notifyListeners();
  }

  void clearSyncMessage() {
    _syncMessage = null;
  }

  // ... (Logs et méthodes CRUD inchangés, ils appellent _refreshData) ...
  List<SyncLog> getAllSyncLogs() {
    return _repository.getAllSyncLogs();
  }
  List<SyncLog> getRecentSyncLogs(int limit) {
    return _repository.getRecentSyncLogs(limit: limit);
  }
  Future<void> clearAllSyncLogs() async {
    await _repository.clearAllSyncLogs();
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionLogic.addTransaction(transaction);
    await _refreshData();
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _transactionLogic.deleteTransaction(transactionId);
    await _refreshData();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _transactionLogic.updateTransaction(transaction);
    await _refreshData();
  }

  void setActivePortfolio(String portfolioId) {
    try {
      _activePortfolio = _portfolios.firstWhere((p) => p.id == portfolioId);
      // Recalculer les totaux pour le nouveau portefeuille
      _refreshData();
    } catch (e) {
      debugPrint("Portefeuille non trouvé : $portfolioId");
    }
  }

  void addDemoPortfolio() {
    if (_portfolios.any((p) => p.name == "Portefeuille de Démo (2020-2025)")) {
      return;
    }
    final demo = _demoDataService.createDemoPortfolio();
    _portfolios.add(demo);
    _activePortfolio = demo;
    _refreshData();
  }

  void addNewPortfolio(String name) {
    final newPortfolio = _repository.createEmptyPortfolio(name);
    _portfolios.add(newPortfolio);
    _activePortfolio = newPortfolio;
    _refreshData(); // Recalcule (totaux seront à 0)
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
    _refreshData(); // Recalcule
  }

  void updateActivePortfolio() {
    if (_activePortfolio == null) return;
    _repository.savePortfolio(_activePortfolio!);
    _refreshData(); // Recalcule
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
        for (final tx in acc.transactions) {
          deleteFutures.add(_transactionLogic.deleteTransaction(tx.id));
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
    _refreshData(); // Recalcule
  }

  Future<void> resetAllData() async {
    await _repository.deleteAllData();
    _portfolios = [];
    _activePortfolio = null;
    await _settingsProvider?.setMigrationV1Done();
    await _settingsProvider?.setMigrationV2Done();
    _refreshData(); // Recalcule (totaux à 0)
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

  Asset? findAssetByTicker(String ticker) {
    if (_activePortfolio == null) return null;
    for (var institution in _activePortfolio!.institutions) {
      for (var account in institution.accounts) {
        for (var asset in account.assets) {
          if (asset.ticker == ticker) return asset;
        }
      }
    }
    return null;
  }

  List<ProjectionData> getProjectionData(int duration) {
    if (_activePortfolio == null) return [];

    // NOTE : Cette projection utilise les valeurs converties
    final totalValue = _convertedTotalValue;
    final totalInvested = _convertedTotalInvested;
    final portfolioAnnualYield = activePortfolioEstimatedAnnualYield;

    // La logique des plans reste la même (elle est basée sur les rendements)
    double totalMonthlyInvestment = 0;
    double weightedPlansYield = 0;
    for (var plan in _activePortfolio!.savingsPlans.where((p) => p.isActive)) {
      final targetAsset = findAssetByTicker(plan.targetTicker);
      final assetYield = (targetAsset?.estimatedAnnualYield ?? 0.0);
      totalMonthlyInvestment += plan.monthlyAmount;
      weightedPlansYield += plan.monthlyAmount * assetYield;
    }
    final double averagePlansYield = (totalMonthlyInvestment > 0)
        ? weightedPlansYield / totalMonthlyInvestment
        : 0.0;

    // TODO: Convertir totalMonthlyInvestment dans la devise de base
    // Pour l'instant, on suppose que les plans sont en devise de base

    return ProjectionCalculator.generateProjectionData(
      duration: duration,
      initialPortfolioValue: totalValue,
      initialInvestedCapital: totalInvested,
      portfolioAnnualYield: portfolioAnnualYield,
      totalMonthlyInvestment: totalMonthlyInvestment,
      averagePlansYield: averagePlansYield,
    );
  }

  Future<void> updateAssetYield(String ticker, double newYield) async {
    final metadata = _repository.getOrCreateAssetMetadata(ticker);
    metadata.updateYield(newYield, isManual: true);
    await _repository.saveAssetMetadata(metadata);
    await _refreshData();
  }

  Future<void> updateAssetPrice(String ticker, double newPrice,
      {String? currency}) async {
    final metadata = _repository.getOrCreateAssetMetadata(ticker);
    final targetCurrency = currency ??
        ((metadata.priceCurrency?.isEmpty ?? true)
            ? _settingsProvider!.baseCurrency
            : metadata.priceCurrency!);
    metadata.updatePrice(newPrice, targetCurrency);
    await _repository.saveAssetMetadata(metadata);
    await _refreshData();
  }
}