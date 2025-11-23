part of '../portfolio_provider.dart';

mixin PortfolioManagement on PortfolioState {
  // ============================================================
  // INITIALISATION
  // ============================================================

  void updateSettings(SettingsProvider settingsProvider) {
    debugPrint(
        "🔄 [Provider] updateSettings: Nouvelle devise = ${settingsProvider.baseCurrency}");

    final oldCurrency = _settingsProvider?.baseCurrency;

    // ✅ COMPARER AUSSI AVEC LA DEVISE ACTUELLEMENT AFFICHÉE
    final currencyChanged = (oldCurrency != null &&
        oldCurrency != settingsProvider.baseCurrency);

    final wasOffline = _settingsProvider?.isOnlineMode ?? false;
    final wasNull = _settingsProvider == null;

    _settingsProvider = settingsProvider;

    if (currencyChanged && !_isLoading) {
      debugPrint("  -> 🚀 Changement de devise détecté: $oldCurrency → ${settingsProvider.baseCurrency}");
      notifyListeners();
      // Le calcul est géré par PortfolioCalculationProvider
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
      // synchroniserLesPrix is in PortfolioSync, but we can call it if we declare it abstract or cast
      // Since PortfolioProvider mixes both, it will be available at runtime.
      // To satisfy analyzer, we should declare it in PortfolioState or cast `this`.
      // Casting `this` to dynamic is risky but works.
      // Better: declare abstract in PortfolioState.
      (this as dynamic).synchroniserLesPrix().catchError((e) {
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
          await refreshData();
        }

        if (_settingsProvider!.isOnlineMode && _activePortfolio != null) {
          debugPrint("  -> Synchronisation des prix post-load...");
          (this as dynamic).synchroniserLesPrix();
        }
      } catch (e) {
        debugPrint("⚠️ Erreur lors de l'initialisation : $e");
      }
    });
  }

  @override
  Future<void> loadAllPortfolios() async {
    debugPrint("--- 🔄 DÉBUT loadAllPortfolios ---");
    _isLoading = true;
    notifyListeners();

    try {
      await refreshData();
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
  @override
  Future<void> refreshData() async {
    debugPrint("--- 🔄 DÉBUT refreshData ---");

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
    // Le calcul est géré par PortfolioCalculationProvider
    
    // 5. Reconstruire le cache des actifs
    _rebuildAssetMap();

    // 6. Sauvegarder le choix actuel pour la prochaine fois
    if (_activePortfolio != null) {
      _settingsProvider?.setLastPortfolioId(_activePortfolio!.id);
      // Mise à jour de l'historique
      await updateHistory(_activePortfolio!.totalValue);
    }

    notifyListeners();
    debugPrint("--- ℹ️ FIN refreshData ---");
  }

  /// Sauvegarde l'historique sans déclencher un rechargement complet de l'app
  Future<void> updateHistory(double totalValue) async {
    if (_activePortfolio == null) return;

    // 1. Reconstruction si vide et transactions présentes
    final hasTransactions = _activePortfolio!.institutions.any((i) => i.accounts.any((a) => a.transactions.isNotEmpty));
    if (_activePortfolio!.valueHistory.isEmpty && hasTransactions) {
       debugPrint("📜 [Provider] Historique vide, reconstruction...");
       final history = _historyService.reconstructHistory(_activePortfolio!);
       _activePortfolio!.valueHistory = history;
       await _repository.savePortfolio(_activePortfolio!);
       // On ne retourne pas, on laisse le point d'aujourd'hui s'ajouter/mettre à jour si besoin
    }

    // 2. Mise à jour du point du jour
    // Utilise la méthode du modèle pour vérifier si une mise à jour est nécessaire
    final hasChanged = _activePortfolio!.addOrUpdateHistoryPoint(totalValue);

    if (hasChanged) {
      debugPrint("📈 [Provider] Mise à jour de l'historique de valeur : $totalValue");
      // Sauvegarde directe dans Hive sans passer par savePortfolio() pour éviter
      // la boucle infinie (refreshData -> _recalculate -> save -> refresh...)
      await _repository.savePortfolio(_activePortfolio!);
    }
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
      notifyListeners();
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
      await refreshData();
      return existingDemo;
    }
    debugPrint("🔄 [Provider] addDemoPortfolio");
    try {
      final demo = await _demoDataService.createDemoPortfolio();
      _portfolios.add(demo);
      _activePortfolio = demo;
      await refreshData();
      return demo;
    } catch (e) {
      debugPrint("❌ Erreur lors de la création du portefeuille de démo: $e");
      return null;
    }
  }

  Future<void> addNewPortfolio(String name) async {
    debugPrint("🔄 [Provider] addNewPortfolio");
    final newPortfolio = _repository.createEmptyPortfolio(name);
    // On doit sauvegarder AVANT de rafraîchir, sinon le refresh va écraser
    // la liste locale avec celle du disque (qui ne contient pas encore le nouveau).
    await _repository.savePortfolio(newPortfolio);
    
    // On peut mettre à jour localement en attendant le refresh pour être plus réactif
    _portfolios.add(newPortfolio);
    _activePortfolio = newPortfolio;
    
    await refreshData();
  }

  @override
  Future<void> savePortfolio(Portfolio portfolio) async {
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
    await _repository.savePortfolio(portfolio);
    await refreshData();
  }

  Future<void> reconstructPortfolioHistory() async {
    if (_activePortfolio == null) return;
    debugPrint("🔄 [Provider] reconstructPortfolioHistory");
    
    final history = _historyService.reconstructHistory(_activePortfolio!);
    _activePortfolio!.valueHistory = history;
    
    await _repository.savePortfolio(_activePortfolio!);
    notifyListeners();
  }

  Future<void> updateActivePortfolio() async {
    if (_activePortfolio == null) return;
    debugPrint("🔄 [Provider] updateActivePortfolio");
    await _repository.savePortfolio(_activePortfolio!);
    await refreshData();
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

    refreshData();
  }

  Future<void> resetAllData() async {
    debugPrint("🔄 [Provider] resetAllData");
    await _repository.deleteAllData();
    _portfolios = [];
    _activePortfolio = null;
    await _settingsProvider?.setMigrationV1Done();
    await _settingsProvider?.setMigrationV2Done();
    refreshData();
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
