import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/01_launch/data/wizard_models.dart';
import 'package:portefeuille/features/01_launch/ui/widgets/wizard_dialogs/add_asset_dialog.dart';

class AddAccountDialog extends StatefulWidget {
  final WizardAccount? initialAccount;
  final bool enableOnlineMode;
  final List<String> existingInstitutions;

  const AddAccountDialog({
    super.key,
    this.initialAccount,
    this.enableOnlineMode = false,
    this.existingInstitutions = const [],
  });

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _institutionController;
  late TextEditingController _nameController;
  late TextEditingController _cashController;
  AccountType _type = AccountType.cto;
  final List<WizardAsset> _assets = [];

  @override
  void initState() {
    super.initState();
    final account = widget.initialAccount;
    _institutionController = TextEditingController(text: account?.institutionName ?? '');
    _nameController = TextEditingController(text: account?.name ?? '');
    _cashController = TextEditingController(text: account?.cashBalance.toString() ?? '0');
    if (account != null) {
      _type = account.type;
      _assets.addAll(account.assets);
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _nameController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialAccount == null ? 'Ajouter un compte' : 'Modifier le compte',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Institution & Type
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TypeAheadField<String>(
                            controller: _institutionController,
                            builder: (context, controller, focusNode) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Institution',
                                  hintText: 'ex: Boursorama, Binance...',
                                  border: OutlineInputBorder(),
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (v) => v?.trim().isEmpty == true ? 'Requis' : null,
                              );
                            },
                            suggestionsCallback: (pattern) {
                              final defaults = [
                                'Trade Republic', 'Boursorama', 'Fortuneo', 'Binance', 
                                'Kraken', 'Coinbase', 'Revolut', 'Degiro', 
                                'Interactive Brokers', 'Crédit Agricole', 'BNP Paribas', 
                                'Société Générale'
                              ];
                              final all = {...widget.existingInstitutions, ...defaults}.toList();
                              return all
                                  .where((inst) => inst.toLowerCase().contains(pattern.toLowerCase()))
                                  .toList();
                            },
                            emptyBuilder: (context) => const SizedBox.shrink(),
                            itemBuilder: (context, suggestion) {
                              // Try to find a logo for this suggestion
                              String? logoPath;
                              final normalized = suggestion.toLowerCase().replaceAll(' ', '_');
                              // Check common names
                              if (normalized.contains('boursorama')) {
                                logoPath = 'assets/logos/boursorama.png';
                              } else if (normalized.contains('trade_republic')) {
                                logoPath = 'assets/logos/trade_republic.png';
                              } else if (normalized.contains('revolut')) {
                                logoPath = 'assets/logos/revolut.png';
                              } else if (normalized.contains('degiro')) {
                                logoPath = 'assets/logos/degiro.png';
                              } else if (normalized.contains('interactive_brokers')) {
                                logoPath = 'assets/logos/interactive_brokers.png';
                              } else if (normalized.contains('binance')) {
                                logoPath = 'assets/logos/binance.png';
                              } else if (normalized.contains('coinbase')) {
                                logoPath = 'assets/logos/coinbase.png';
                              } else if (normalized.contains('kraken')) {
                                logoPath = 'assets/logos/kraken.png';
                              } else if (normalized.contains('fortuneo')) {
                                logoPath = 'assets/logos/fortuneo.png';
                              } else if (normalized.contains('credit_agricole')) {
                                logoPath = 'assets/logos/credit_agricole.png';
                              } else if (normalized.contains('bnp')) {
                                logoPath = 'assets/logos/bnp_paribas.png';
                              } else if (normalized.contains('societe_generale')) {
                                logoPath = 'assets/logos/societe_generale.png';
                              }

                              return ListTile(
                                leading: logoPath != null 
                                  ? Image.asset(logoPath, width: 24, height: 24, errorBuilder: (_,__,___) => const Icon(Icons.account_balance))
                                  : const Icon(Icons.account_balance),
                                title: Text(suggestion),
                              );
                            },
                            onSelected: (suggestion) {
                              _institutionController.text = suggestion;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<AccountType>(
                            initialValue: _type,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                            items: AccountType.values.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Nom & Cash
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom du compte',
                              hintText: 'ex: PEA, Compte Courant...',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            validator: (v) => v?.trim().isEmpty == true ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _cashController,
                            decoration: const InputDecoration(
                              labelText: 'Solde Espèces',
                              suffixText: '€',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                            ],
                            validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? 'Invalid' : null,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Assets Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Actifs (${_assets.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addAsset,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_assets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Aucun actif. Ajoutez des actions, cryptos, etc. si ce compte en contient.',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ..._assets.map((asset) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                            child: Text(asset.ticker.substring(0, 1))),
                        title:
                            Text(asset.name, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${CurrencyFormatter.formatQuantity(asset.quantity)} x ${asset.currentPrice} €\n= ${(asset.quantity * asset.currentPrice).toStringAsFixed(2)} €',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editAsset(asset),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 20, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _assets.remove(asset)),
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Enregistrer le compte'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAsset() async {
    final result = await showDialog<WizardAsset>(
      context: context,
      builder: (context) => AddAssetDialog(enableOnlineMode: widget.enableOnlineMode),
    );
    if (result != null) {
      setState(() => _assets.add(result));
    }
  }

  Future<void> _editAsset(WizardAsset asset) async {
    final result = await showDialog<WizardAsset>(
      context: context,
      builder: (context) => AddAssetDialog(
        initialAsset: asset,
        enableOnlineMode: widget.enableOnlineMode,
      ),
    );
    if (result != null) {
      setState(() {
        final index = _assets.indexOf(asset);
        _assets[index] = result;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final account = WizardAccount(
        id: widget.initialAccount?.id,
        name: _nameController.text.trim(),
        type: _type,
        institutionName: _institutionController.text.trim(),
        cashBalance: double.parse(_cashController.text),
        assets: _assets,
      );
      Navigator.pop(context, account);
    }
  }
}
