// lib/features/01_launch/ui/widgets/initial_setup_wizard.dart
// Assistant multi-étapes pour configurer le portefeuille initial

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/features/01_launch/data/wizard_models.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';

// Import des étapes (à créer)
import 'wizard_steps/step1_online_mode.dart';
import 'wizard_steps/step2_institutions.dart';
import 'wizard_steps/step3_accounts.dart';
import 'wizard_steps/step4_assets.dart';
import 'wizard_steps/step5_summary.dart';

class InitialSetupWizard extends StatefulWidget {
  final String portfolioName;

  const InitialSetupWizard({
    super.key,
    required this.portfolioName,
  });

  @override
  State<InitialSetupWizard> createState() => _InitialSetupWizardState();
}

class _InitialSetupWizardState extends State<InitialSetupWizard> {
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isSaving = false;

  // État du wizard
  bool _enableOnlineMode = false;
  final List<WizardInstitution> _institutions = [];
  final List<WizardAccount> _accounts = [];
  final List<WizardAsset> _assets = [];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Confirmation avant de quitter
        if (_currentStep > 0) {
          final shouldExit = await _showExitConfirmation();
          return shouldExit ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              Text('Configuration initiale (${_currentStep + 1}/$_totalSteps)'),
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousStep,
                )
              : null,
        ),
        body: Column(
          children: [
            // Indicateur de progression
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey[300],
            ),
            // Contenu de l'étape actuelle
            Expanded(
              child: _buildCurrentStep(),
            ),
            // Boutons de navigation
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Step1OnlineMode(
          enableOnlineMode: _enableOnlineMode,
          onChanged: (value) => setState(() => _enableOnlineMode = value),
        );
      case 1:
        return Step2Institutions(
          institutions: _institutions,
          onInstitutionsChanged: () => setState(() {}),
        );
      case 2:
        return Step3Accounts(
          institutions: _institutions,
          accounts: _accounts,
          onAccountsChanged: () => setState(() {}),
        );
      case 3:
        return Step4Assets(
          accounts: _accounts,
          assets: _assets,
          enableOnlineMode: _enableOnlineMode,
          onAssetsChanged: () => setState(() {}),
        );
      case 4:
        return Step5Summary(
          institutions: _institutions,
          accounts: _accounts,
          assets: _assets,
          portfolioName: widget.portfolioName,
        );
      default:
        return const Center(child: Text('Étape inconnue'));
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton Précédent
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Précédent'),
            )
          else
            const SizedBox.shrink(),

          // Bouton Suivant / Terminer MODIFIÉ
          ElevatedButton.icon(
            // Désactive le bouton si sauvegarde en cours
            onPressed: (_canProceed() && !_isSaving) ? _nextStep : null,
            // Affiche un loader si sauvegarde en cours
            icon: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Icon(_currentStep == _totalSteps - 1 ? Icons.check : Icons.arrow_forward),
            label: Text(_currentStep == _totalSteps - 1
                ? (_isSaving ? 'Création...' : 'Terminer')
                : 'Suivant'),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true; // Toujours possible de continuer (choix facultatif)
      case 1:
        return _institutions.isNotEmpty &&
            _institutions.every((i) => i.isValid);
      case 2:
        return _accounts.isNotEmpty && _accounts.every((a) => a.isValid);
      case 3:
        return true; // Les actifs sont facultatifs
      case 4:
        return true; // Récapitulatif
      default:
        return false;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _nextStep() async {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Dernière étape : terminer le wizard
      await _finishWizard();
    }
  }

  Future<void> _finishWizard() async {
    if (_isSaving) return; // 🔒 Sécurité anti-double clic
    setState(() => _isSaving = true);

    try {
      final portfolioProvider = context.read<PortfolioProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      // 1. Activer le mode en ligne si demandé
      if (_enableOnlineMode && !settingsProvider.isOnlineMode) {
        settingsProvider.toggleOnlineMode(true);
      }

      // 2. Créer le portefeuille
      await _createPortfolioData(portfolioProvider);

      // 3. Attendre et recharger
      await Future.delayed(const Duration(milliseconds: 500));
      await portfolioProvider.loadAllPortfolios();

      // 4. Synchronisation éventuelle
      if (_enableOnlineMode && settingsProvider.isOnlineMode) {
        debugPrint('🔄 Mode en ligne : sync des prix...');
        try {
          await portfolioProvider.forceSynchroniserLesPrix();
        } catch (e) {
          debugPrint('⚠️ Erreur sync prix : $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('❌ Erreur wizard : $e');
      // En cas d'erreur, on réactive le bouton pour permettre de réessayer
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _createPortfolioData(PortfolioProvider provider) async {
    // Générer les transactions à partir des données du wizard
    try {
      const uuid = Uuid();

      // 1. Créer le portefeuille
      provider.addNewPortfolio(widget.portfolioName);
      await Future.delayed(const Duration(
          milliseconds: 200)); // Attendre que le provider se mette à jour

      // 2. Créer les institutions et comptes
      for (final wizardInstitution in _institutions) {
        // Créer l'institution
        final institution = Institution(
          id: uuid.v4(),
          name: wizardInstitution.name,
          accounts: [],
        );
        provider.addInstitution(institution);
        await Future.delayed(const Duration(milliseconds: 50));

        // Créer les comptes pour cette institution
        final institutionAccounts = _accounts
            .where((a) => a.institutionName == wizardInstitution.name)
            .toList();

        for (final wizardAccount in institutionAccounts) {
          // Créer le compte
          final account = Account(
            id: uuid.v4(),
            name: wizardAccount.name,
            type: wizardAccount.type,
          );
          provider.addAccount(institution.id, account);
          await Future.delayed(const Duration(milliseconds: 50));

          // 3. Calculer le total des actifs pour ce compte
          final accountAssets = _assets
              .where((a) => a.accountDisplayName == wizardAccount.displayName)
              .toList();

          final totalAssetsValue = accountAssets.fold<double>(
            0.0,
            (sum, asset) => sum + (asset.quantity * asset.averagePrice),
          );

          // 4. Créer une transaction Deposit pour le solde initial
          // IMPORTANT : On ajoute le cash + la valeur des actifs car les actifs
          // vont être "achetés" via des transactions Buy qui vont déduire du cash
          final totalDeposit = wizardAccount.cashBalance + totalAssetsValue;

          if (totalDeposit > 0) {
            final depositTransaction = Transaction(
              id: uuid.v4(),
              accountId: account.id,
              type: TransactionType.Deposit,
              date: DateTime.now(),
              amount: totalDeposit,
              fees: 0.0,
              notes: 'Solde initial (assistant de configuration)',
            );
            await provider.addTransaction(depositTransaction);
            await Future.delayed(const Duration(milliseconds: 50));
          }

          // 5. Créer les transactions Buy pour les actifs

          for (final wizardAsset in accountAssets) {
            final buyTransaction = Transaction(
              id: uuid.v4(),
              accountId: account.id,
              type: TransactionType.Buy,
              date: wizardAsset.firstPurchaseDate,
              amount: -(wizardAsset.quantity *
                  wizardAsset.averagePrice), // Négatif pour un achat
              fees: 0.0,
              assetTicker: wizardAsset.ticker,
              assetName: wizardAsset.name,
              assetType: wizardAsset.type,
              quantity: wizardAsset.quantity,
              price: wizardAsset.averagePrice,
              notes: 'Position initiale (assistant de configuration)',
            );
            await provider.addTransaction(buyTransaction);
            await Future.delayed(const Duration(milliseconds: 50));

            // Sauvegarder le prix actuel dans les métadonnées
            await provider.updateAssetPrice(
                wizardAsset.ticker, wizardAsset.currentPrice);
            await Future.delayed(const Duration(milliseconds: 50));

            // Sauvegarder le rendement estimé dans les métadonnées (si fourni)
            if (wizardAsset.estimatedYield != null) {
              await provider.updateAssetYield(
                  wizardAsset.ticker, wizardAsset.estimatedYield!);
              await Future.delayed(const Duration(milliseconds: 50));
            }
          }
        }
      }

      // 5. Forcer une mise à jour complète du provider
      provider.updateActivePortfolio();

      debugPrint('✅ Portefeuille créé avec succès !');
      debugPrint('  - ${_institutions.length} institution(s)');
      debugPrint('  - ${_accounts.length} compte(s)');
      debugPrint('  - ${_assets.length} actif(s)');
    } catch (e) {
      debugPrint('❌ Erreur lors de la création du portefeuille : $e');
      rethrow;
    }
  }

  Future<bool?> _showExitConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter l\'assistant ?'),
        content: const Text(
          'Vos données ne seront pas sauvegardées si vous quittez maintenant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
