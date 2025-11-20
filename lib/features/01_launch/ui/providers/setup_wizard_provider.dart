import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/features/01_launch/data/wizard_models.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';

class SetupWizardProvider extends ChangeNotifier {
  // État du wizard
  String _portfolioName = '';
  bool _enableOnlineMode = false;
  final List<WizardAccount> _accounts = [];
  bool _isSaving = false;

  // Getters
  String get portfolioName => _portfolioName;
  bool get enableOnlineMode => _enableOnlineMode;
  List<WizardAccount> get accounts => List.unmodifiable(_accounts);
  bool get isSaving => _isSaving;

  // Setters
  void setPortfolioName(String name) {
    _portfolioName = name;
    notifyListeners();
  }

  void setOnlineMode(bool value) {
    _enableOnlineMode = value;
    notifyListeners();
  }

  // Gestion des comptes
  void addAccount(WizardAccount account) {
    _accounts.add(account);
    notifyListeners();
  }

  void updateAccount(String id, WizardAccount newAccount) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _accounts[index] = newAccount;
      notifyListeners();
    }
  }

  void removeAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // Validation
  bool get isStep1Valid => _portfolioName.trim().isNotEmpty;
  bool get isStep2Valid => true; // Toujours valide, on peut avoir 0 comptes
  bool get canFinish => isStep1Valid && !_isSaving;

  // Logique de création
  Future<void> createPortfolio(
    PortfolioProvider portfolioProvider,
    SettingsProvider settingsProvider,
  ) async {
    if (_isSaving) return;
    _isSaving = true;
    notifyListeners();

    try {
      // 1. Configurer le mode en ligne
      if (_enableOnlineMode && !settingsProvider.isOnlineMode) {
        settingsProvider.toggleOnlineMode(true);
      }

      // 2. Créer le portefeuille
      const uuid = Uuid();
      portfolioProvider.addNewPortfolio(_portfolioName);
      
      // Petit délai pour laisser le temps à Hive de réagir si nécessaire
      // (Idéalement on devrait attendre un Future retourné par addNewPortfolio)
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Grouper les comptes par institution pour créer les institutions
      final institutionsMap = <String, List<WizardAccount>>{};
      for (var account in _accounts) {
        if (!institutionsMap.containsKey(account.institutionName)) {
          institutionsMap[account.institutionName] = [];
        }
        institutionsMap[account.institutionName]!.add(account);
      }

      // 4. Créer Institutions, Comptes et Transactions
      for (final entry in institutionsMap.entries) {
        final institutionName = entry.key;
        final accountsList = entry.value;

        // Créer l'institution
        final institution = Institution(
          id: uuid.v4(),
          name: institutionName,
          accounts: [],
        );
        portfolioProvider.addInstitution(institution);

        for (final wizardAccount in accountsList) {
          // Créer le compte
          final account = Account(
            id: uuid.v4(),
            name: wizardAccount.name,
            type: wizardAccount.type,
          );
          portfolioProvider.addAccount(institution.id, account);

          // Calculer le dépôt initial (Cash + Valeur d'achat des actifs)
          // On considère que le cashBalance est le "reste" en cash.
          // Donc le dépôt initial = cashBalance + somme(qty * price_achat)
          
          double totalAssetsCost = 0;
          for (var asset in wizardAccount.assets) {
            totalAssetsCost += asset.quantity * asset.averagePrice;
          }
          
          final initialDeposit = wizardAccount.cashBalance + totalAssetsCost;

          if (initialDeposit > 0) {
            final depositTx = Transaction(
              id: uuid.v4(),
              accountId: account.id,
              type: TransactionType.Deposit,
              date: DateTime.now().subtract(const Duration(minutes: 5)), // Un peu avant
              amount: initialDeposit,
              fees: 0.0,
              notes: 'Solde initial (Assistant)',
            );
            await portfolioProvider.addTransaction(depositTx);
          }

          // Créer les transactions d'achat pour les actifs
          for (final wizardAsset in wizardAccount.assets) {
            final buyTx = Transaction(
              id: uuid.v4(),
              accountId: account.id,
              type: TransactionType.Buy,
              date: wizardAsset.firstPurchaseDate,
              amount: -(wizardAsset.quantity * wizardAsset.averagePrice),
              fees: 0.0,
              assetTicker: wizardAsset.ticker,
              assetName: wizardAsset.name,
              assetType: wizardAsset.type,
              quantity: wizardAsset.quantity,
              price: wizardAsset.averagePrice,
              notes: 'Position initiale (Assistant)',
            );
            await portfolioProvider.addTransaction(buyTx);

            // Mettre à jour le prix actuel
            await portfolioProvider.updateAssetPrice(
              wizardAsset.ticker,
              wizardAsset.currentPrice,
            );

            // Mettre à jour le rendement estimé
            if (wizardAsset.estimatedYield != null) {
              await portfolioProvider.updateAssetYield(
                wizardAsset.ticker,
                wizardAsset.estimatedYield!,
              );
            }
          }
        }
      }

      // 5. Rafraîchir et Sync
      portfolioProvider.updateActivePortfolio();
      
      if (_enableOnlineMode && settingsProvider.isOnlineMode) {
        try {
          await portfolioProvider.forceSynchroniserLesPrix();
        } catch (e) {
          debugPrint('Erreur sync prix: $e');
        }
      }

    } catch (e) {
      debugPrint('Erreur création portefeuille: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
