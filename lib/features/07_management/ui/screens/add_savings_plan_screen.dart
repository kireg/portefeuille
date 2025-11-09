// lib/features/07_management/ui/screens/add_savings_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
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

class _AddSavingsPlanScreenState extends State<AddSavingsPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _nameController;
  late final TextEditingController _monthlyAmountController;
  late bool _isActive;
  
  Asset? _selectedAsset;
  List<Asset> _availableAssets = [];

  @override
  void initState() {
    super.initState();
    
    // Récupérer tous les actifs du portefeuille
    final portfolio = Provider.of<PortfolioProvider>(context, listen: false).activePortfolio;
    if (portfolio != null) {
      for (var institution in portfolio.institutions) {
        for (var account in institution.accounts) {
          _availableAssets.addAll(account.assets);
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
    if (plan != null) {
      _selectedAsset = _availableAssets.firstWhere(
        (asset) => asset.ticker == plan.targetTicker,
        orElse: () => _availableAssets.isNotEmpty ? _availableAssets.first : Asset(
          id: '',
          name: 'Inconnu',
          ticker: plan.targetTicker,
          quantity: 0,
          averagePrice: 0,
          currentPrice: 0,
        ),
      );
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
          const SnackBar(content: Text('Veuillez sélectionner un actif cible')),
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
                  isEditing ? 'Modifier le plan d\'épargne' : 'Nouveau plan d\'épargne',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            // Montant mensuel
            TextFormField(
              controller: _monthlyAmountController,
              decoration: const InputDecoration(
                labelText: 'Montant mensuel (€) *',
                hintText: 'ex: 150',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            const SizedBox(height: 16),

            // Sélection de l'actif cible
            if (_availableAssets.isEmpty)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Aucun actif disponible',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                value: _selectedAsset,
                decoration: const InputDecoration(
                  labelText: 'Actif cible *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_center_outlined),
                  helperText: 'Sélectionnez l\'actif dans lequel investir',
                ),
                items: _availableAssets.map((asset) {
                  return DropdownMenuItem(
                    value: asset,
                    child: Text(
                      '${asset.name} (${asset.ticker}) - ${(asset.estimatedAnnualYield * 100).toStringAsFixed(1)}%',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
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
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de l\'actif sélectionné',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rendement estimé:', style: theme.textTheme.bodyMedium),
                          Text(
                            '${(_selectedAsset!.estimatedAnnualYield * 100).toStringAsFixed(1)}% /an',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

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
            const SizedBox(height: 24),

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
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
    );
  }
}
