// lib/features/07_management/ui/screens/add_savings_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddSavingsPlanScreen extends StatefulWidget {
  /// Plan existant à modifier (null = mode création)
  final SavingsPlan? existingPlan;
  const AddSavingsPlanScreen({
    super.key,
    this.existingPlan,
  });

  @override
  State<AddSavingsPlanScreen> createState() => _AddSavingsPlanScreenState();
}

// Classe pour grouper les actifs par institution et compte
class _GroupedAsset {
  final Asset asset;
  final String institutionName;
  final String accountName;

  _GroupedAsset({
    required this.asset,
    required this.institutionName,
    required this.accountName,
  });
}

class _AddSavingsPlanScreenState extends State<AddSavingsPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _nameController;
  late final TextEditingController _monthlyAmountController;
  late bool _isActive;

  Asset? _selectedAsset;
  final List<_GroupedAsset> _groupedAssets = [];

  @override
  void initState() {
    super.initState();

    // Récupérer tous les actifs du portefeuille avec leur contexte
    final portfolio =
        Provider.of<PortfolioProvider>(context, listen: false).activePortfolio;
    if (portfolio != null) {
      for (var institution in portfolio.institutions) {
        for (var account in institution.accounts) {
          for (var asset in account.assets) {
            _groupedAssets.add(_GroupedAsset(
              asset: asset,
              institutionName: institution.name,
              accountName: account.name,
            ));
          }
        }
      }
    }

    // Initialiser avec les valeurs existantes ou vides
    final plan = widget.existingPlan;
    _nameController = TextEditingController(text: plan?.name ?? '');
    _monthlyAmountController = TextEditingController(
      text: plan?.monthlyAmount.toStringAsFixed(0) ?? '',
    );
    _isActive = plan?.isActive ?? true;

    // Si en mode édition, trouver l'actif correspondant
    if (plan != null && _groupedAssets.isNotEmpty) {
      final grouped = _groupedAssets.firstWhere(
            (g) => g.asset.ticker == plan.targetTicker,
        orElse: () => _groupedAssets.first,
      );
      _selectedAsset = grouped.asset;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monthlyAmountController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedAsset == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un actif cible'),
            showCloseIcon: true,
          ),
        );
        return;
      }

      final plan = SavingsPlan(
        id: widget.existingPlan?.id ?? _uuid.v4(),
        name: _nameController.text,
        monthlyAmount: double.tryParse(_monthlyAmountController.text) ?? 0,
        targetTicker: _selectedAsset!.ticker,
        isActive: _isActive,
      );
      final provider = Provider.of<PortfolioProvider>(context, listen: false);

      if (widget.existingPlan != null) {
        provider.updateSavingsPlan(widget.existingPlan!.id, plan);
      } else {
        provider.addSavingsPlan(plan);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existingPlan != null;
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          bottom: keyboardPadding + 16.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing
                        ? 'Modifier le plan d\'épargne'
                        : 'Nouveau plan d\'épargne',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              AppSpacing.gapM,

              // Nom du plan
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du plan *',
                  hintText: 'ex: Achat mensuel ETF World',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
              ),
              AppSpacing.gapM,

              // Montant mensuel
              TextFormField(
                controller: _monthlyAmountController,
                decoration: const InputDecoration(
                  labelText: 'Montant mensuel (€) *',
                  hintText: 'ex: 150',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le montant est obligatoire';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Le montant doit être supérieur à 0';
                  }
                  return null;
                },
              ),
              AppSpacing.gapM,

              // Sélection de l'actif cible
              if (_groupedAssets.isEmpty)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.warning_amber,
                            color: Colors.orange.shade700, size: AppComponentSizes.iconLarge),
                        AppSpacing.gapS,
                        Text(
                          'Aucun actif disponible',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.orange.shade900,
                          ),
                        ),
                        AppSpacing.gapXs,
                        Text(
                          'Vous devez d\'abord ajouter des actifs à votre portefeuille',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                DropdownButtonFormField<Asset>(
                  initialValue: _selectedAsset,
                  decoration: const InputDecoration(
                    labelText: 'Actif cible *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business_center_outlined),
                    helperText: 'Sélectionnez l\'actif dans lequel investir',
                  ),
                  isExpanded: true,
                  menuMaxHeight: 400,
                  items: _buildDropdownItems(context),
                  onChanged: (asset) {
                    setState(() {
                      _selectedAsset = asset;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner un actif';
                    }
                    return null;
                  },
                ),

              // Affichage des informations de l'actif sélectionné
              if (_selectedAsset != null) ...[
                AppSpacing.gapM,
                Card(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: AppOpacities.decorative),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations de l\'actif sélectionné',
                          style: theme.textTheme.labelLarge,
                        ),
                        AppSpacing.gapS,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ticker:', style: theme.textTheme.bodyMedium),
                            Text(
                              _selectedAsset!.ticker,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapXs,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rendement estimé:',
                                style: theme.textTheme.bodyMedium),
                            Text(
                              '${(_selectedAsset!.estimatedAnnualYield * 100).toStringAsFixed(1)}% /an',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapXs,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Localisation:',
                                style: theme.textTheme.bodyMedium),
                            Flexible(
                              child: Text(
                                _getAssetLocation(_selectedAsset!),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              AppSpacing.gapM,

              // Plan actif/inactif
              SwitchListTile(
                title: const Text('Plan actif'),
                subtitle: Text(
                  _isActive
                      ? 'Le plan est actif et sera pris en compte dans les projections'
                      : 'Le plan est désactivé (non pris en compte)',
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                secondary: Icon(
                  _isActive ? Icons.check_circle : Icons.cancel,
                  color: _isActive ? Colors.green : Colors.grey,
                ),
              ),
              AppSpacing.gapL,

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Enregistrer' : 'Créer le plan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              AppSpacing.gapS,
            ],
          ),
        ),
      ),
    );
  }

  // Construction des items du dropdown avec groupement par institution/compte
  List<DropdownMenuItem<Asset>> _buildDropdownItems(BuildContext context) {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    final theme = Theme.of(context);

    // Grouper par institution puis par compte
    final Map<String, Map<String, List<_GroupedAsset>>> grouped = {};

    for (var groupedAsset in _groupedAssets) {
      grouped.putIfAbsent(groupedAsset.institutionName, () => {});
      grouped[groupedAsset.institutionName]!
          .putIfAbsent(groupedAsset.accountName, () => []);
      grouped[groupedAsset.institutionName]![groupedAsset.accountName]!
          .add(groupedAsset);
    }

    final List<DropdownMenuItem<Asset>> items = [];

    // Trier les institutions par nom
    final sortedInstitutions = grouped.keys.toList()..sort();

    for (var institutionName in sortedInstitutions) {
      final accounts = grouped[institutionName]!;

      // Header de l'institution (désactivé, non sélectionnable)
      items.add(
        DropdownMenuItem<Asset>(
          enabled: false,
          value: null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              institutionName,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      );

      // Trier les comptes par nom
      final sortedAccounts = accounts.keys.toList()..sort();

      for (var accountName in sortedAccounts) {
        final assetsInAccount = accounts[accountName]!;

        // Sous-header du compte (désactivé, non sélectionnable)
        items.add(
          DropdownMenuItem<Asset>(
            enabled: false,
            value: null,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 2.0),
              child: Text(
                '└ $accountName',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ),
        );

        // Actifs du compte
        for (var groupedAsset in assetsInAccount) {
          final asset = groupedAsset.asset;
          final metadata = provider.allMetadata[asset.ticker];
          final isin = metadata?.isin;

          items.add(
            DropdownMenuItem<Asset>(
              value: asset,
              child: Padding(
                padding: const EdgeInsets.only(left: 32.0, right: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${asset.name} (${asset.ticker})',
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '${(asset.estimatedAnnualYield * 100).toStringAsFixed(1)}%${isin != null && isin.isNotEmpty ? ' • ISIN: $isin' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: AppOpacities.prominent),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }

      // Séparateur entre institutions
      if (institutionName != sortedInstitutions.last) {
        items.add(
          const DropdownMenuItem<Asset>(
            enabled: false,
            value: null,
            child: Divider(height: 8),
          ),
        );
      }
    }

    return items;
  }

  // Récupérer la localisation d'un actif
  String _getAssetLocation(Asset asset) {
    final grouped = _groupedAssets.firstWhere(
          (g) => g.asset.ticker == asset.ticker,
      orElse: () => _GroupedAsset(
        asset: asset,
        institutionName: 'Inconnu',
        accountName: 'Inconnu',
      ),
    );
    return '${grouped.institutionName} › ${grouped.accountName}';
  }
}