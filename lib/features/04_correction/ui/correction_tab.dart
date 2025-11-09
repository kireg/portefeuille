// lib/features/04_correction/ui/correction_tab.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_institution_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_account_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_asset_screen.dart';
import 'package:provider/provider.dart';

import '../../00_app/providers/portfolio_provider.dart';

// Imports des widgets extraits
import 'widgets/correction_content.dart';
import 'widgets/save_changes_bar.dart';

class CorrectionTab extends StatefulWidget {
  const CorrectionTab({super.key});

  @override
  State<CorrectionTab> createState() => _CorrectionTabState();
}

class _CorrectionTabState extends State<CorrectionTab>
    with AutomaticKeepAliveClientMixin {
  Portfolio? _editedPortfolio;
  bool _hasChanges = false;
  Key _listKey = UniqueKey();

  // Mémorise l'instance source pour la comparaison (Correction du Bug)
  Portfolio? _sourcePortfolioInstance;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final portfolioProvider =
    Provider.of<PortfolioProvider>(context, listen: false);

    // Si l'ID a changé, ou si l'instance a changé ET qu'on n'a pas de modifs
    if (_editedPortfolio == null ||
        _editedPortfolio!.id != portfolioProvider.activePortfolio?.id ||
        (_sourcePortfolioInstance != portfolioProvider.activePortfolio && !_hasChanges)) {
      _resetLocalCopy();
    }
  }

  void _resetLocalCopy() {
    final portfolioProvider =
    Provider.of<PortfolioProvider>(context, listen: false);

    if (portfolioProvider.activePortfolio != null) {
      _sourcePortfolioInstance = portfolioProvider.activePortfolio;
      _editedPortfolio = _sourcePortfolioInstance!.deepCopy();
    } else {
      _sourcePortfolioInstance = null;
      _editedPortfolio = null;
    }
    setState(() {
      _listKey = UniqueKey();
      _hasChanges = false;
    });
  }

  void _onDataChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _saveChanges() {
    final portfolioProvider =
    Provider.of<PortfolioProvider>(context, listen: false);
    if (_editedPortfolio != null) {
      portfolioProvider.savePortfolio(_editedPortfolio!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modifications enregistrées !'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _hasChanges = false;
      });
    }
  }

  // --- Logique de gestion (Ajout / Suppression) ---

  void _addInstitution() {
    if (_editedPortfolio == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddInstitutionScreen(
        onInstitutionCreated: (newInstitution) {
          setState(() {
            _editedPortfolio!.institutions.add(newInstitution);
            _onDataChanged();
          });
        },
      ),
    );
  }

  void _deleteInstitution(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'institution ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${_editedPortfolio!.institutions[index].name}" et tous ses comptes ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              setState(() {
                _editedPortfolio!.institutions.removeAt(index);
                _onDataChanged();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _addAccount(int instIndex) {
    if (_editedPortfolio == null) return;
    final institutionId = _editedPortfolio!.institutions[instIndex].id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddAccountScreen(
        institutionId: institutionId,
        onAccountCreated: (newAccount) {
          setState(() {
            _editedPortfolio!.institutions[instIndex].accounts.add(newAccount);
            _onDataChanged();
          });
        },
      ),
    );
  }

  void _deleteAccount(int instIndex, int accIndex) {
    final instName = _editedPortfolio!.institutions[instIndex].name;
    final accName = _editedPortfolio!.institutions[instIndex].accounts[accIndex].name;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: Text(
          'Voulez-vous vraiment supprimer le compte "$accName" de "$instName" et tous ses actifs ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              setState(() {
                _editedPortfolio!.institutions[instIndex].accounts.removeAt(accIndex);
                _onDataChanged();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _addAsset(int instIndex, int accIndex) {
    if (_editedPortfolio == null) return;
    final accountId = _editedPortfolio!.institutions[instIndex].accounts[accIndex].id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddAssetScreen(
        accountId: accountId,
        onAssetCreated: (newAsset) {
          setState(() {
            _editedPortfolio!.institutions[instIndex].accounts[accIndex].assets.add(newAsset);
            _onDataChanged();
          });
        },
      ),
    );
  }

  void _deleteAsset(int instIndex, int accIndex, int assetIndex) {
    final assetName = _editedPortfolio!.institutions[instIndex].accounts[accIndex].assets[assetIndex].name;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'actif ?'),
        content: Text('Voulez-vous vraiment supprimer "$assetName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              setState(() {
                _editedPortfolio!.institutions[instIndex].accounts[accIndex].assets.removeAt(assetIndex);
                _onDataChanged();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // --- BUILD METHOD (Refactorisé) ---

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final activePortfolioFromProvider = portfolioProvider.activePortfolio;

    if (activePortfolioFromProvider == null) {
      return const Center(child: Text("Aucun portefeuille à corriger."));
    }

    // Logique de synchronisation
    final bool idHasChanged = _editedPortfolio == null ||
        _editedPortfolio!.id != activePortfolioFromProvider.id;
    final bool providerHasNewInstance =
        _sourcePortfolioInstance != activePortfolioFromProvider;

    if (idHasChanged || (providerHasNewInstance && !_hasChanges)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resetLocalCopy());
      return const Center(child: CircularProgressIndicator());
    }

    // Le build est maintenant propre
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: _hasChanges ? 72.0 : 0),
          child: CorrectionContent(
            listKey: _listKey,
            institutions: _editedPortfolio!.institutions,
            onAddInstitution: _addInstitution,
            onDeleteInstitution: _deleteInstitution,
            onAddAccount: _addAccount,
            onDeleteAccount: _deleteAccount,
            onAddAsset: _addAsset,
            onDeleteAsset: _deleteAsset,
            onDataChanged: _onDataChanged,
          ),
        ),
        if (_hasChanges)
          SaveChangesBar(
            onCancel: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Annuler les modifications ?'),
                  content: const Text(
                      'Toutes les modifications non sauvegardées seront perdues.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Non')),
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Oui')),
                  ],
                ),
              );
              if (confirmed == true) {
                _resetLocalCopy();
              }
            },
            onSave: _saveChanges,
          ),
      ],
    );
  }
}