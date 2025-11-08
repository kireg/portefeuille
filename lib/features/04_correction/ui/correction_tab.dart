// lib/features/04_correction/ui/correction_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_institution_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_account_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_asset_screen.dart';
import 'package:provider/provider.dart';

import '../../00_app/providers/portfolio_provider.dart';

// Imports des nouveaux widgets
import 'widgets/asset_editor_tile.dart';
import 'widgets/account_type_label.dart';

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

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On vérifie si la copie locale est nulle OU si l'utilisateur
    // a changé de portefeuille actif pendant que cet onglet était "vivant".
    final portfolioProvider =
    Provider.of<PortfolioProvider>(context, listen: false);
    if (_editedPortfolio == null ||
        _editedPortfolio!.id != portfolioProvider.activePortfolio?.id) {
      _resetLocalCopy();
    }
  }

  void _resetLocalCopy() {
    final portfolioProvider =
    Provider.of<PortfolioProvider>(context, listen: false);

    // CORRIGÉ : Utilise activePortfolio
    if (portfolioProvider.activePortfolio != null) {
      _editedPortfolio = portfolioProvider.activePortfolio!.deepCopy();
    } else {
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

      // --- CORRECTION DE L'ERREUR ---
      // L'ancienne méthode 'updatePortfolio' s'appelle 'savePortfolio'
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    // On écoute le provider pour détecter les changements de portefeuille
    final activePortfolio = Provider.of<PortfolioProvider>(context).activePortfolio;

    if (activePortfolio == null) {
      return const Center(child: Text("Aucun portefeuille à corriger."));
    }

    // Si le portefeuille actif change, on force le reset de la copie locale
    if (_editedPortfolio == null || _editedPortfolio!.id != activePortfolio.id) {
      // On utilise addPostFrameCallback pour éviter un setState pendant le build
      WidgetsBinding.instance.addPostFrameCallback((_) => _resetLocalCopy());
      return const Center(child: CircularProgressIndicator()); // État de chargement
    }

    final institutions = _editedPortfolio!.institutions;
    const bottomBarHeight = 72.0;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: _hasChanges ? bottomBarHeight : 0),
          child: Column(
            children: [
              // Bouton pour ajouter une institution
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton.icon(
                  onPressed: _addInstitution,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une Institution'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  key: _listKey,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: institutions.length,
                  itemBuilder: (context, instIndex) {
              final inst = institutions[instIndex];
              final instTotal = inst.totalValue;

              return Card(
                margin:
                const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                color: theme.colorScheme.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  title: Row(
                    children: [
                      Expanded(
                          child: Text(inst.name,
                              style: theme.textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: theme.colorScheme.error,
                        tooltip: 'Supprimer l\'institution',
                        onPressed: () => _deleteInstitution(instIndex),
                      ),
                      Flexible(
                        child: Text(
                          CurrencyFormatter.format(instTotal),
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    ...inst.accounts.map((account) {
                      final accIndex = inst.accounts.indexOf(account);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      child: Card(
                        color: Color.lerp(theme.colorScheme.surface,
                            theme.colorScheme.background, 0.5),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        account.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                            color: theme.colorScheme.primary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Widget extrait
                                    Flexible(
                                      child: AccountTypeLabel(
                                        label: account.type.displayName,
                                        description: account.type.description,
                                        backgroundColor: theme.colorScheme.primary
                                            .withOpacity(0.12),
                                        textColor: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    color: theme.colorScheme.error,
                                    tooltip: 'Supprimer le compte',
                                    onPressed: () => _deleteAccount(instIndex, accIndex),
                                  ),
                                  Flexible(
                                    child: Text(
                                      CurrencyFormatter.format(account.totalValue),
                                      style: theme.textTheme.titleSmall?.copyWith(
                                          color: theme.colorScheme.primary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (account.type != AccountType.crypto) ...[
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(top: 8.0),
                                      child: TextFormField(
                                        initialValue: account.cashBalance
                                            .toStringAsFixed(2),
                                        decoration: InputDecoration(
                                          labelText: 'Liquidités',
                                          labelStyle: TextStyle(
                                              color:
                                              theme.colorScheme.primary),
                                          floatingLabelBehavior:
                                          FloatingLabelBehavior.auto,
                                          border:
                                          const OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: theme
                                                    .colorScheme.primary
                                                    .withOpacity(0.18)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: theme
                                                    .colorScheme.primary,
                                                width: 1.4),
                                          ),
                                          isDense: false,
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 12.0),
                                          prefixIcon: Icon(
                                              Icons
                                                  .account_balance_wallet_outlined,
                                              color:
                                              theme.colorScheme.primary),
                                          prefixIconConstraints:
                                          const BoxConstraints(
                                              minWidth: 40,
                                              minHeight: 40),
                                          suffixText: '€',
                                        ),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                            fontWeight:
                                            FontWeight.w600),
                                        textAlignVertical:
                                        TextAlignVertical.center,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal: true),
                                        onChanged: (value) {
                                          account.cashBalance =
                                              double.tryParse(value) ??
                                                  account.cashBalance;
                                          _onDataChanged();
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final targetWidth = 380.0;
                                      final spacing = 12.0;
                                      int columns =
                                      (constraints.maxWidth /
                                          (targetWidth + spacing))
                                          .floor();
                                      columns = columns.clamp(1, 3);

                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                        const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          childAspectRatio: 1.8,
                                          crossAxisSpacing: spacing,
                                          mainAxisSpacing: spacing,
                                          mainAxisExtent: 180,
                                        ),
                                        itemCount: account.assets.length,
                                        itemBuilder: (context, assetIndex) {
                                          final asset =
                                          account.assets[assetIndex];
                                          // Widget extrait avec bouton de suppression
                                          return Stack(
                                            children: [
                                              AssetEditorTile(
                                                key: ValueKey(
                                                    '${inst.id}_${account.id}_${asset.id}'),
                                                asset: asset,
                                                onChanged: _onDataChanged,
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.close,
                                                    size: 18,
                                                    color: theme.colorScheme.error,
                                                  ),
                                                  tooltip: 'Supprimer l\'actif',
                                                  onPressed: () => _deleteAsset(instIndex, accIndex, assetIndex),
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.8),
                                                    padding: const EdgeInsets.all(4),
                                                    minimumSize: const Size(24, 24),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  // Bouton pour ajouter un actif
                                  OutlinedButton.icon(
                                    onPressed: () => _addAsset(instIndex, accIndex),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Ajouter un actif'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 40),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                    // Bouton pour ajouter un compte
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: OutlinedButton.icon(
                        onPressed: () => _addAccount(instIndex),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un compte'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
              ],
            ),
          ),
        if (_hasChanges)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              bottom: true,
              child: Material(
                elevation: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.12),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modifications non sauvegardées',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pensez à sauvegarder vos changements',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: TextButton.icon(
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Annuler'),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text(
                                    'Annuler les modifications ?'),
                                content: const Text(
                                    'Toutes les modifications non sauvegardées seront perdues.'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Non')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Oui')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              _resetLocalCopy();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Enregistrer'),
                          onPressed: _saveChanges,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}