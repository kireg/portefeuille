// lib/features/01_launch/ui/widgets/initial_setup_wizard.dart
// Assistant multi-étapes pour configurer le portefeuille initial

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/features/01_launch/ui/providers/setup_wizard_provider.dart';
import 'package:portefeuille/features/01_launch/ui/widgets/wizard_dialogs/add_account_dialog.dart';
import 'package:portefeuille/features/01_launch/data/wizard_models.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';

// ignore_for_file: use_build_context_synchronously

class InitialSetupWizard extends StatelessWidget {
  final String portfolioName;

  const InitialSetupWizard({
    super.key,
    required this.portfolioName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SetupWizardProvider()..setPortfolioName(portfolioName),
      child: const _WizardContent(),
    );
  }
}

class _WizardContent extends StatefulWidget {
  const _WizardContent();

  @override
  State<_WizardContent> createState() => _WizardContentState();
}

class _WizardContentState extends State<_WizardContent> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SetupWizardProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        } else {
          final shouldPop = await _showExitConfirmation(context);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Configuration (${_currentStep + 1}/$_totalSteps)'),
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _currentStep--),
                )
              : null,
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppColors.border,
            ),
            Expanded(
              child: _buildStepContent(context, provider),
            ),
            _buildBottomBar(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, SetupWizardProvider provider) {
    switch (_currentStep) {
      case 0:
        return _Step1Config(provider: provider);
      case 1:
        return _Step2Accounts(provider: provider);
      case 2:
        return _Step3Summary(provider: provider);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar(BuildContext context, SetupWizardProvider provider) {
    final isLastStep = _currentStep == _totalSteps - 1;
    final canProceed = _canProceed(provider);

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOverlay05,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: provider.isSaving ? null : () => setState(() => _currentStep--),
              child: const Text('Précédent'),
            )
          else
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Annuler'),
            ),
          ElevatedButton.icon(
            onPressed: canProceed
                ? () {
                    if (isLastStep) {
                      _finishWizard(context, provider);
                    } else {
                      setState(() => _currentStep++);
                    }
                  }
                : null,
            icon: provider.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : Icon(isLastStep ? Icons.check : Icons.arrow_forward),
            label: Text(isLastStep
                ? (provider.isSaving ? 'Création...' : 'Terminer')
                : 'Suivant'),
          ),
        ],
      ),
    );
  }

  bool _canProceed(SetupWizardProvider provider) {
    if (provider.isSaving) return false;
    switch (_currentStep) {
      case 0:
        return provider.isStep1Valid;
      case 1:
        return provider.isStep2Valid;
      case 2:
        return provider.canFinish;
      default:
        return false;
    }
  }

  Future<void> _finishWizard(BuildContext context, SetupWizardProvider provider) async {
    try {
      final portfolioProvider = context.read<PortfolioProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      
      await provider.createPortfolio(portfolioProvider, settingsProvider, transactionProvider);
      
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter ?'),
        content: const Text('Vos modifications seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// --- Step Widgets ---

class _Step1Config extends StatelessWidget {
  final SetupWizardProvider provider;

  const _Step1Config({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commençons par les bases',
            style: AppTypography.h2,
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: provider.portfolioName,
            decoration: const InputDecoration(
              labelText: 'Nom du portefeuille',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder),
            ),
            onChanged: provider.setPortfolioName,
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            title: const Text('Activer le mode en ligne'),
            subtitle: const Text(
              'Récupération automatique des prix et synchronisation (optionnel)',
            ),
            value: provider.enableOnlineMode,
            onChanged: provider.setOnlineMode,
            secondary: const Icon(Icons.cloud_sync),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _Step2Accounts extends StatelessWidget {
  final SetupWizardProvider provider;

  const _Step2Accounts({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimens.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vos comptes d\'investissement',
                style: AppTypography.h2,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ajoutez vos comptes (PEA, CTO, Crypto...) et leurs actifs.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.accounts.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                  itemCount: provider.accounts.length,
                  itemBuilder: (context, index) {
                    final account = provider.accounts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppDimens.paddingS),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(_getIconForType(account)),
                        ),
                        title: Text(account.name),
                        subtitle: Text(
                          '${account.institutionName} • ${account.assets.length} actifs',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${account.totalValue.toStringAsFixed(2)} €',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer', style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'delete') {
                                  provider.removeAccount(account.id);
                                } else if (value == 'edit') {
                                  _editAccount(context, account);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () => _editAccount(context, account),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addAccount(context),
              icon: const Icon(Icons.add),
              label: const Text('AJOUTER UN COMPTE'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(AppDimens.paddingM),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Aucun compte ajouté',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(WizardAccount account) {
    // Simple mapping based on type name or similar
    if (account.type.name.toLowerCase().contains('crypto')) return Icons.currency_bitcoin;
    if (account.type.name.toLowerCase().contains('pea')) return Icons.euro;
    return Icons.account_balance;
  }

  Future<void> _addAccount(BuildContext context) async {
    final institutions = provider.accounts.map((a) => a.institutionName).toSet().toList();
    final result = await showDialog<WizardAccount>(
      context: context,
      builder: (context) => AddAccountDialog(
        enableOnlineMode: provider.enableOnlineMode,
        existingInstitutions: institutions,
      ),
    );
    if (result != null) {
      provider.addAccount(result);
    }
  }

  Future<void> _editAccount(BuildContext context, WizardAccount account) async {
    final institutions = provider.accounts.map((a) => a.institutionName).toSet().toList();
    final result = await showDialog<WizardAccount>(
      context: context,
      builder: (context) => AddAccountDialog(
        initialAccount: account,
        enableOnlineMode: provider.enableOnlineMode,
        existingInstitutions: institutions,
      ),
    );
    if (result != null) {
      provider.updateAccount(account.id, result);
    }
  }
}

class _Step3Summary extends StatelessWidget {
  final SetupWizardProvider provider;

  const _Step3Summary({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalValue = provider.accounts.fold(0.0, (sum, a) => sum + a.totalValue);
    final totalAssets = provider.accounts.fold(0, (sum, a) => sum + a.assets.length);

    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: AppTypography.h2,
          ),
          const SizedBox(height: 24),
          _buildSummaryCard(context, 'Portefeuille', provider.portfolioName, Icons.folder),
          const SizedBox(height: 16),
          _buildSummaryCard(
            context,
            'Valeur Totale Estimée',
            '${totalValue.toStringAsFixed(2)} €',
            Icons.savings,
            isHighlight: true,
          ),
          const SizedBox(height: 24),
          const Text('Détails', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildDetailRow('Comptes', '${provider.accounts.length}'),
          _buildDetailRow('Actifs totaux', '$totalAssets'),
          _buildDetailRow('Mode en ligne', provider.enableOnlineMode ? 'Activé' : 'Désactivé'),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, {bool isHighlight = false}) {
    return Card(
      color: isHighlight ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: isHighlight ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isHighlight ? Theme.of(context).primaryColor : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}