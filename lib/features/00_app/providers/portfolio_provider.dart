// lib/features/00_app/providers/portfolio_provider.dart

import 'package:flutter/material.dart';
import 'dart:convert'; // Pour jsonEncode
import 'package:portefeuille/core/data/services/backup_service.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/aggregated_asset.dart';
import 'package:portefeuille/core/data/models/aggregated_portfolio_data.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/projection_data.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/models/background_activity.dart';
import 'package:portefeuille/features/00_app/services/calculation_service.dart';
import 'package:portefeuille/features/00_app/services/demo_data_service.dart';
import 'package:portefeuille/features/00_app/services/hydration_service.dart';
import 'package:portefeuille/features/00_app/services/migration_service.dart';
import 'package:portefeuille/features/00_app/services/sync_service.dart';
import 'package:portefeuille/features/00_app/services/transaction_service.dart';
import 'package:portefeuille/features/00_app/services/institution_service.dart';
import 'package:uuid/uuid.dart';

class PortfolioProvider extends ChangeNotifier {
  final PortfolioRepository _repository;
  final ApiService _apiService;
  final Uuid _uuid;

  // Services
  late final MigrationService _migrationService;
  late final SyncService _syncService;
  late final TransactionService _transactionService;
  late final HydrationService _hydrationService;
  late final DemoDataService _demoDataService;
  late final CalculationService _calculationService;
  late final BackupService _backupService;
  late final InstitutionService _institutionService;

  // Settings
  SettingsProvider? _settingsProvider;
  bool _isFirstSettingsUpdate = true;

  // État
  List<Portfolio> _portfolios = [];
  Portfolio? _activePortfolio;
  bool _isLoading = true;
  BackgroundActivity _activity = const Idle();
  String? _syncMessage;
  AggregatedPortfolioData _aggregatedData = AggregatedPortfolioData.empty;
  
  // Cache pour optimisation O(1)
  final Map<String, Asset> _assetMap = {};

  // Getters - État brut
  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get activePortfolio => _activePortfolio;
  bool get isLoading => _isLoading;
  BackgroundActivity get activity => _activity;
  bool get isProcessingInBackground => _activity.isActive;
  String? get syncMessage => _syncMessage;
  Map<String, AssetMetadata> get allMetadata =>
      _repository.getAllAssetMetadata();
  InstitutionService get institutionService => _institutionService;

  // Getters - Données calculées
  String get currentBaseCurrency => _aggregatedData.baseCurrency;
  double get activePortfolioTotalValue => _aggregatedData.totalValue;
  double get activePortfolioTotalInvested => _aggregatedData.totalInvested; // AJOUT
  double get activePortfolioCashValue => _aggregatedData.valueByAssetType[AssetType.Cash] ?? 0.0; // AJOUT
  double get activePortfolioTotalPL => _aggregatedData.totalPL;
  double get activePortfolioTotalPLPercentage {
    if (_aggregatedData.totalInvested == 0.0) return 0.0;
    return _aggregatedData.totalPL / _aggregatedData.totalInvested;
  }

  double get activePortfolioEstimatedAnnualYield =>
      _aggregatedData.estimatedAnnualYield;

  double getConvertedAccountValue(String accountId) =>
      _aggregatedData.accountValues[accountId] ?? 0.0;
  double getConvertedAccountPL(String accountId) =>
      _aggregatedData.accountPLs[accountId] ?? 0.0;
  double getConvertedAccountInvested(String accountId) =>
      _aggregatedData.accountInvested[accountId] ?? 0.0;

  double getConvertedAssetTotalValue(String assetId) =>
      _aggregatedData.assetTotalValues[assetId] ?? 0.0;
  double getConvertedAssetPL(String assetId) =>
      _aggregatedData.assetPLs[assetId] ?? 0.0;

  List<AggregatedAsset> get aggregatedAssets =>
      _aggregatedData.aggregatedAssets;
  Map<AssetType, double> get aggregatedValueByAssetType =>
      _aggregatedData.valueByAssetType;

  bool get hasCrowdfunding =>
      (_aggregatedData.valueByAssetType[AssetType.RealEstateCrowdfunding] ?? 0.0) > 0;

  PortfolioProvider({
    required PortfolioRepository repository,
    required ApiService apiService,
    Uuid? uuid,
  })  : _repository = repository,
        _apiService = apiService,
        _uuid = uuid ?? const Uuid() {
    // Initialisation des services
    _migrationService = MigrationService(repository: _repository, uuid: _uuid);
    _syncService = SyncService(
      repository: _repository,
      apiService: _apiService,
      uuid: _uuid,
    );
    _transactionService = TransactionService(repository: _repository);
    _hydrationService = HydrationService(
      repository: _repository,
      apiService: _apiService,
    );
    _demoDataService = DemoDataService(repository: _repository, uuid: _uuid);
    _calculationService = CalculationService(apiService: _apiService);
    _backupService = BackupService();
    _institutionService = InstitutionService();
    _institutionService.loadInstitutions(); // Chargement asynchrone (fire & forget)
    loadAllPortfolios();
  }

  // ============================================================
  // INITIALISATION
  // ============================================================

  void updateSettings(SettingsProvider settingsProvider) {
    debugPrint(
        "🔄 [Provider] updateSettings: Nouvelle devise = ${settingsProvider.baseCurrency}");

    final oldCurrency = _settingsProvider?.baseCurrency;

    // ✅ COMPARER AUSSI AVEC LA DEVISE ACTUELLEMENT AFFICHÉE
    final currencyChanged = (oldCurrency != null &&
        oldCurrency != settingsProvider.baseCurrency) ||
        (_aggregatedData.baseCurrency != settingsProvider.baseCurrency);

    final wasOffline = _settingsProvider?.isOnlineMode ?? false;
    final wasNull = _settingsProvider == null;

    _settingsProvider = settingsProvider;

    if (currencyChanged && !_isLoading) {
      debugPrint("  -> 🚀 Changement de devise détecté: ${_aggregatedData.baseCurrency} → ${settingsProvider.baseCurrency}");
      _setActivity(const Recalculating());
      notifyListeners();
      Future.microtask(() => _recalculateAggregatedData());
      return;
    }

    if (_isFirstSettingsUpdate) {
      _isFirstSettingsUpdate = false;
      _handleFirstSettingsUpdate();
      return;
    }

    if (_settingsProvider!.isOnlineMode &&
        !wasOffline &&
        !wasNull &&
        _activePortfolio != null) {
      debugPrint("  -> Mode en ligne activé, synchronisation...");
      synchroniserLesPrix().catchError((e) {
        debugPrint("⚠️ Impossible de synchroniser les prix : $e");
      });
    }
  }

  Future<void> _handleFirstSettingsUpdate() async {
    debugPrint("  -> Premier updateSettings, attente chargement...");

    Future.delayed(Duration.zero, () async {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      try {
        bool needsReload = false;

        if (!_settingsProvider!.migrationV1Done) {
          debugPrint("  -> Lancement Migration V1...");
          final hasChanges =
          await _migrationService.runMigrationV1(_portfolios);
          if (hasChanges) {
            await _settingsProvider!.setMigrationV1Done();
            needsReload = true;
          }
        }

        if (_settingsProvider!.migrationV1Done &&
            !_settingsProvider!.migrationV2Done) {
          debugPrint("  -> Lancement Migration V2...");
          final hasChanges = await _migrationService.runMigrationV2();
          if (hasChanges) {
            await _settingsProvider!.setMigrationV2Done();
            needsReload = true;
          }
        }

        if (needsReload) {
          debugPrint("  -> 🚀 Rechargement après migration");
          await _refreshDataFromSource();
        }

        if (_settingsProvider!.isOnlineMode && _activePortfolio != null) {
          debugPrint("  -> Synchronisation des prix post-load...");
          await synchroniserLesPrix();
        }
      } catch (e) {
        debugPrint("⚠️ Erreur lors de l'initialisation : $e");
      }
    });
  }

  Future<void> loadAllPortfolios() async {
    debugPrint("--- 🔄 DÉBUT loadAllPortfolios ---");
    _isLoading = true;
    notifyListeners();

    try {
      await _refreshDataFromSource();
    } catch (e) {
      debugPrint("ERREUR FATALE loadAllPortfolios: $e");
    } finally {
      _isLoading = false;
      debugPrint("--- ℹ️ FIN loadAllPortfolios ---");
      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH & RECALCUL
  // ============================================================

  /// Rechargement complet (lourd) : hydratation + calcul
  Future<void> _refreshDataFromSource() async {
    debugPrint("--- 🔄 DÉBUT _refreshDataFromSource ---");

    // 1. Hydratation
    final rawPortfolios = await _hydrationService.hydrateAll();

    // 2. NETTOYAGE : On filtre les portefeuilles invalides (noms vides ou nulls)
    _portfolios = rawPortfolios.where((p) => p.id.isNotEmpty && p.name.trim().isNotEmpty).toList();

    // 3. Sélection du portfolio actif
    if (_portfolios.isNotEmpty) {
      // A. Essayer de garder le portefeuille actuel s'il existe encore
      if (_activePortfolio != null) {
        try {
          _activePortfolio = _portfolios.firstWhere((p) => p.id == _activePortfolio!.id);
        } catch (e) {
          _activePortfolio = null;
        }
      }

      // B. Si aucun actif, essayer de récupérer le dernier utilisé via les Settings
      if (_activePortfolio == null && _settingsProvider != null) {
        final lastId = _settingsProvider!.lastPortfolioId;
        if (lastId != null && lastId.isNotEmpty) {
          try {
            _activePortfolio = _portfolios.firstWhere((p) => p.id == lastId);
          } catch (_) {
            // L'ID sauvegardé ne correspond à rien, on prendra le défaut
          }
        }
      }

      // C. Fallback : Prendre le premier de la liste par défaut
      _activePortfolio ??= _portfolios.first;

    } else {
      _activePortfolio = null;
    }

    // 4. Calcul
    await _recalculateAggregatedData();
    
    // 5. Reconstruire le cache des actifs
    _rebuildAssetMap();

    // 6. Sauvegarder le choix actuel pour la prochaine fois
    if (_activePortfolio != null) {
      _settingsProvider?.setLastPortfolioId(_activePortfolio!.id);
    }

    debugPrint("--- ℹ️ FIN _refreshDataFromSource ---");
  }

  /// Recalcul léger (uniquement les conversions)
  /// Recalcul léger (uniquement les conversions)
  Future<void> _recalculateAggregatedData() async {
    debugPrint("--- 🔄 DÉBUT _recalculateAggregatedData ---");

    final targetCurrency = _settingsProvider?.baseCurrency ?? 'EUR';

    try {
      _aggregatedData = await _calculationService.calculate(
        portfolio: _activePortfolio,
        targetCurrency: targetCurrency,
        allMetadata: allMetadata,
      );
      debugPrint("  -> ✅ Calcul OK. Valeur totale: ${_aggregatedData.totalValue} $targetCurrency");

      // ▼▼▼ NOUVEAU : Sauvegarde du point d'historique ▼▼▼
      if (_activePortfolio != null && !_isLoading) {
        // On enregistre l'historique seulement si le calcul a réussi
        await _saveHistorySnapshot(_aggregatedData.totalValue);
      }
      // ▲▲▲ FIN NOUVEAU ▲▲▲

    } catch (e) {
      debugPrint("  -> ❌ ERREUR CALCUL: $e");
      debugPrint("  -> StackTrace: ${StackTrace.current}");
    } finally {
      _setActivity(const Idle());
      debugPrint("  -> 📢 notifyListeners() appelé");
      notifyListeners();
      debugPrint("--- ℹ️ FIN _recalculateAggregatedData ---");
    }
  }

  /// Sauvegarde l'historique sans déclencher un rechargement complet de l'app
  Future<void> _saveHistorySnapshot(double currentValue) async {
    if (_activePortfolio == null) return;

    // Utilise la méthode du modèle pour vérifier si une mise à jour est nécessaire
    final hasChanged = _activePortfolio!.addOrUpdateHistoryPoint(currentValue);

    if (hasChanged) {
      debugPrint("📈 [Provider] Mise à jour de l'historique de valeur : $currentValue");
      // Sauvegarde directe dans Hive sans passer par savePortfolio() pour éviter
      // la boucle infinie (_refreshDataFromSource -> _recalculate -> save -> _refresh...)
      await _repository.savePortfolio(_activePortfolio!);
    }
  }

  // ============================================================
  // SYNCHRONISATION
  // ============================================================

  Future<void> synchroniserLesPrix() async {
    if (!_canSync()) return;

    debugPrint("🔄 [Provider] synchroniserLesPrix");
    _setActivity(const Syncing(0, 0));
    _syncMessage = "Synchronisation en cours...";
    notifyListeners();

    final result = await _syncService.synchronize(_activePortfolio!);

    if (result.hasUpdates) {
      await _refreshDataFromSource();
    }

    _setActivity(const Idle());
    _syncMessage = result.getSummaryMessage();
    notifyListeners();
  }

  Future<void> forceSynchroniserLesPrix() async {
    if (!_canSync()) return;

    debugPrint("🔄 [Provider] forceSynchroniserLesPrix");
    _setActivity(const Syncing(0, 0));
    _syncMessage = "Synchronisation forcée en cours...";
    notifyListeners();

    final result = await _syncService.forceSync(_activePortfolio!);

    if (result.hasUpdates) {
      await _refreshDataFromSource();
    }

    _setActivity(const Idle());
    _syncMessage = result.getSummaryMessage();
    notifyListeners();
  }

  bool _canSync() {
    return _activePortfolio != null &&
        _activity is Idle &&
        _settingsProvider?.isOnlineMode == true;
  }

  void clearSyncMessage() {
    _syncMessage = null;
    notifyListeners();
  }

  // ============================================================
  // SYNC LOGS
  // ============================================================

  List<SyncLog> getAllSyncLogs() => _repository.getAllSyncLogs();

  List<SyncLog> getRecentSyncLogs(int limit) =>
      _repository.getRecentSyncLogs(limit: limit);

  Future<void> clearAllSyncLogs() async {
    await _repository.clearAllSyncLogs();
    notifyListeners();
  }

  // ============================================================
  // TRANSACTIONS
  // ============================================================

  Future<void> addTransaction(Transaction transaction) async {
    debugPrint("🔄 [Provider] addTransaction");
    await _transactionService.add(transaction);
    await _refreshDataFromSource();
  }

  Future<void> deleteTransaction(String transactionId) async {
    debugPrint("🔄 [Provider] deleteTransaction");
    await _transactionService.delete(transactionId);
    await _refreshDataFromSource();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    debugPrint("🔄 [Provider] updateTransaction");
    await _transactionService.update(transaction);
    await _refreshDataFromSource();
  }

  // ============================================================
  // GESTION PORTFOLIOS
  // ============================================================

  void setActivePortfolio(String portfolioId) {
    debugPrint("🔄 [Provider] setActivePortfolio");
    try {
      _activePortfolio = _portfolios.firstWhere((p) => p.id == portfolioId);
      // Sauvegarde de la préférence
      _settingsProvider?.setLastPortfolioId(portfolioId);
      _recalculateAggregatedData();
    } catch (e) {
      debugPrint("Portefeuille non trouvé : $portfolioId");
    }
  }

  Future<Portfolio?> addDemoPortfolio() async {
    if (_portfolios.any((p) => p.name == "Portefeuille de Démo (2020-2025)")) {
      // Portfolio de démo déjà existant, le sélectionner comme actif
      final existingDemo = _portfolios.firstWhere(
          (p) => p.name == "Portefeuille de Démo (2020-2025)");
      _activePortfolio = existingDemo;
      await _refreshDataFromSource();
      return existingDemo;
    }
    debugPrint("🔄 [Provider] addDemoPortfolio");
    try {
      final demo = await _demoDataService.createDemoPortfolio();
      _portfolios.add(demo);
      _activePortfolio = demo;
      await _refreshDataFromSource();
      return demo;
    } catch (e) {
      debugPrint("❌ Erreur lors de la création du portefeuille de démo: $e");
      return null;
    }
  }

  void addNewPortfolio(String name) {
    debugPrint("🔄 [Provider] addNewPortfolio");
    final newPortfolio = _repository.createEmptyPortfolio(name);
    _portfolios.add(newPortfolio);
    _activePortfolio = newPortfolio;
    _refreshDataFromSource();
  }

  void savePortfolio(Portfolio portfolio) {
    debugPrint("🔄 [Provider] savePortfolio");
    final index = _portfolios.indexWhere((p) => p.id == portfolio.id);
    if (index != -1) {
      _portfolios[index] = portfolio;
    } else {
      _portfolios.add(portfolio);
    }
    if (_activePortfolio?.id == portfolio.id) {
      _activePortfolio = portfolio;
    }
    _repository.savePortfolio(portfolio);
    _refreshDataFromSource();
  }

  void updateActivePortfolio() {
    if (_activePortfolio == null) return;
    debugPrint("🔄 [Provider] updateActivePortfolio");
    _repository.savePortfolio(_activePortfolio!);
    _refreshDataFromSource();
  }

  void renameActivePortfolio(String newName) {
    if (_activePortfolio == null) return;
    debugPrint("🔄 [Provider] renameActivePortfolio");
    _activePortfolio!.name = newName;
    updateActivePortfolio();
  }

  Future<void> deletePortfolio(String portfolioId) async {
    debugPrint("🔄 [Provider] deletePortfolio");
    Portfolio? portfolioToDelete;
    try {
      portfolioToDelete = _portfolios.firstWhere((p) => p.id == portfolioId);
    } catch (e) {
      debugPrint("Impossible de supprimer : ID $portfolioId non trouvé.");
      return;
    }

    final deleteFutures = <Future<void>>[];
    for (final inst in portfolioToDelete.institutions) {
      for (final acc in inst.accounts) {
        for (final tx in acc.transactions) {
          deleteFutures.add(_transactionService.delete(tx.id));
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

    _refreshDataFromSource();
  }

  Future<void> resetAllData() async {
    debugPrint("🔄 [Provider] resetAllData");
    await _repository.deleteAllData();
    _portfolios = [];
    _activePortfolio = null;
    await _settingsProvider?.setMigrationV1Done();
    await _settingsProvider?.setMigrationV2Done();
    _refreshDataFromSource();
  }

  // ============================================================
  // INSTITUTIONS & ACCOUNTS
  // ============================================================

  void addInstitution(Institution newInstitution) {
    if (_activePortfolio == null) return;
    debugPrint("🔄 [Provider] addInstitution");
    final updatedPortfolio = _activePortfolio!.deepCopy();
    updatedPortfolio.institutions.add(newInstitution);
    savePortfolio(updatedPortfolio);
  }

  void updateInstitution(Institution updatedInstitution) {
    if (_activePortfolio == null) return;
    debugPrint("🔄 [Provider] updateInstitution");
    final updatedPortfolio = _activePortfolio!.deepCopy();
    final index = updatedPortfolio.institutions.indexWhere((i) => i.id == updatedInstitution.id);
    if (index != -1) {
      updatedPortfolio.institutions[index] = updatedInstitution;
      savePortfolio(updatedPortfolio);
    } else {
      debugPrint("Institution non trouvée : ${updatedInstitution.id}");
    }
  }

  Future<void> deleteInstitution(String institutionId) async {
    if (_activePortfolio == null) return;
    debugPrint("🔄 [Provider] deleteInstitution");

    final updatedPortfolio = _activePortfolio!.deepCopy();
    
    // 1. Trouver l'institution à supprimer
    Institution? institutionToDelete;
    try {
      institutionToDelete = updatedPortfolio.institutions.firstWhere((i) => i.id == institutionId);
    } catch (e) {
      debugPrint("Institution non trouvée : $institutionId");
      return;
    }

    // 2. Supprimer toutes les transactions associées à tous les comptes de cette institution
    final deleteFutures = <Future<void>>[];
    for (final acc in institutionToDelete.accounts) {
      for (final tx in acc.transactions) {
        deleteFutures.add(_transactionService.delete(tx.id));
      }
    }
    
    if (deleteFutures.isNotEmpty) {
      await Future.wait(deleteFutures);
    }

    // 3. Supprimer l'institution
    updatedPortfolio.institutions.removeWhere((i) => i.id == institutionId);

    // 4. Sauvegarder
    savePortfolio(updatedPortfolio);
  }

  void addAccount(String institutionId, Account newAccount) {
    if (_activePortfolio == null) return;
    debugPrint("🔄 [Provider] addAccount");
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

  void updateAccount(String institutionId, Account updatedAccount) {
    if (_activePortfolio == null) return;
    debugPrint("🔄 [Provider] updateAccount");

    final updatedPortfolio = _activePortfolio!.deepCopy();
    try {
      // 1. Trouver l'institution
      final institution = updatedPortfolio.institutions
          .firstWhere((inst) => inst.id == institutionId);

      // 2. Trouver l'index de l'ancien compte
      final accountIndex =
      institution.accounts.indexWhere((acc) => acc.id == updatedAccount.id);

      if (accountIndex != -1) {
        // 3. Remplacer l'ancien compte par le nouveau
        institution.accounts[accountIndex] = updatedAccount;
        // 4. Sauvegarder
        savePortfolio(updatedPortfolio);
      } else {
        debugPrint("Compte non trouvé : ${updatedAccount.id}");
      }
    } catch (e) {
      debugPrint("Institution non trouvée : $institutionId");
    }
  }

  Future<void> deleteAccount(String institutionId, String accountId) async {
    if (_activePortfolio == null) return;
    debugPrint("🔄 [Provider] deleteAccount");

    final updatedPortfolio = _activePortfolio!.deepCopy();
    try {
      // 1. Trouver l'institution
      final institution = updatedPortfolio.institutions
          .firstWhere((inst) => inst.id == institutionId);

      // 2. Trouver le compte à supprimer
      Account? accountToDelete;
      try {
        accountToDelete =
            institution.accounts.firstWhere((acc) => acc.id == accountId);
      } catch (e) {
        debugPrint("Compte non trouvé : $accountId");
        return;
      }

      // 3. Supprimer toutes les transactions associées (TRÈS IMPORTANT)
      final deleteFutures = <Future<void>>[];
      for (final tx in accountToDelete.transactions) {
        deleteFutures.add(_transactionService.delete(tx.id));
      }
      if (deleteFutures.isNotEmpty) {
        await Future.wait(deleteFutures);
      }

      // 4. Supprimer le compte de la liste
      institution.accounts.removeWhere((acc) => acc.id == accountId);

      // 5. Sauvegarder
      savePortfolio(updatedPortfolio);
    } catch (e) {
      debugPrint("Institution non trouvée : $institutionId");
    }
  }

  // ============================================================
  // SAVINGS PLANS
  // ============================================================

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

  // ============================================================
  // ASSETS
  // ============================================================

  void _rebuildAssetMap() {
    _assetMap.clear();
    if (_activePortfolio == null) return;
    
    for (var institution in _activePortfolio!.institutions) {
      for (var account in institution.accounts) {
        for (var asset in account.assets) {
          _assetMap[asset.ticker] = asset;
        }
      }
    }
  }

  Asset? findAssetByTicker(String ticker) {
    return _assetMap[ticker];
  }

  Future<void> updateAssetYield(String ticker, double newYield) async {
    debugPrint("🔄 [Provider] updateAssetYield");
    final metadata = _repository.getOrCreateAssetMetadata(ticker);
    metadata.updateYield(newYield, isManual: true);
    await _repository.saveAssetMetadata(metadata);
    await _refreshDataFromSource();
  }

  Future<void> updateAssetPrice(String ticker, double newPrice,
      {String? currency}) async {
    debugPrint("🔄 [Provider] updateAssetPrice");
    final metadata = _repository.getOrCreateAssetMetadata(ticker);
    final targetCurrency = currency ??
        ((metadata.priceCurrency?.isEmpty ?? true)
            ? _settingsProvider!.baseCurrency
            : metadata.priceCurrency!);
    metadata.updatePrice(newPrice, targetCurrency);
    await _repository.saveAssetMetadata(metadata);
    await _refreshDataFromSource();
  }

  // ============================================================
  // ASSET METADATA
  // ============================================================

  Future<void> updateAssetMetadata(AssetMetadata metadata) async {
    await _repository.saveAssetMetadata(metadata);
    // Recharger les données pour que les actifs (Assets) soient mis à jour avec les nouvelles métadonnées (lat/lon, etc.)
    await _refreshDataFromSource();
  }

  // ============================================================
  // PROJECTIONS
  // ============================================================

  List<ProjectionData> getProjectionData(int duration) {
    if (_activePortfolio == null) return [];

    final totalValue = _aggregatedData.totalValue;
    final totalInvested = _aggregatedData.totalInvested;
    final portfolioAnnualYield = activePortfolioEstimatedAnnualYield;

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

    return ProjectionCalculator.generateProjectionData(
      duration: duration,
      initialPortfolioValue: totalValue,
      initialInvestedCapital: totalInvested,
      portfolioAnnualYield: portfolioAnnualYield,
      totalMonthlyInvestment: totalMonthlyInvestment,
      averagePlansYield: averagePlansYield,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _setActivity(BackgroundActivity activity) {
    _activity = activity;
  }

  // ============================================================
  // EXPORT / IMPORT
  // ============================================================

  /// Récupère toutes les données de l'application sous forme de chaîne JSON.
  Future<String> getExportJson() async {
    debugPrint("🔄 [Provider] getExportJson");
    try {
      final jsonString = await _backupService.exportData();
      return jsonString;
    } catch (e) {
      debugPrint("❌ [Provider] Erreur lors de l'exportation: $e");
      // Retourne un JSON d'erreur
      return jsonEncode({'error': 'Impossible d\'exporter les données: $e'});
    }
  }

  /// Importe les données depuis une chaîne JSON et remplace tout.
  Future<void> importDataFromJson(String json) async {
    debugPrint("🔄 [Provider] importDataFromJson");
    _isLoading = true;
    _setActivity(const Recalculating()); // Utilise l'état de recalcul
    notifyListeners();

    try {
      await _backupService.importData(json);
      debugPrint("✅ [Provider] Importation réussie. Rechargement des données...");

      // Forcer un rechargement complet des données du portefeuille
      await loadAllPortfolios(); // Ceci appelle déjà notifyListeners() à la fin

      // Forcer un rechargement des settings (couleur, devise, etc.)
      // Le '?' est une sécurité si _settingsProvider est null
      await _settingsProvider?.reloadSettings();

    } catch (e) {
      debugPrint("❌ [Provider] Erreur lors de l'importation: $e");
      // En cas d'erreur, recharger les données (qui devraient être vides)
      // pour éviter un état incohérent.
      await loadAllPortfolios();
      rethrow; // Propage l'erreur à l'UI
    } finally {
      _isLoading = false;
      _setActivity(const Idle());
      // notifyListeners() est déjà appelé par loadAllPortfolios
    }
  }


}