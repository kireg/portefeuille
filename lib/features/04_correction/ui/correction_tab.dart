import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:provider/provider.dart';

import '../../00_app/providers/portfolio_provider.dart';


class CorrectionTab extends StatefulWidget {
  const CorrectionTab({super.key});

  @override
  State<CorrectionTab> createState() => _CorrectionTabState();
}

class _CorrectionTabState extends State<CorrectionTab> with AutomaticKeepAliveClientMixin {
  Portfolio? _editedPortfolio;
  bool _hasChanges = false;
  Key _listKey = UniqueKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editedPortfolio == null) {
      _resetLocalCopy();
    }
  }

  void _resetLocalCopy() {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    if (portfolioProvider.portfolio != null) {
      _editedPortfolio = portfolioProvider.portfolio!.deepCopy();
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
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    if (_editedPortfolio != null) {
      portfolioProvider.updatePortfolio(_editedPortfolio!);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_editedPortfolio == null) {
      return const Center(child: Text("Aucun portefeuille à corriger."));
    }

    final allAssets = _editedPortfolio!.institutions
            .expand((inst) => inst.accounts)
            .expand((acc) => acc.assets)
            .toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            key: _listKey,
            padding: const EdgeInsets.all(8.0),
            itemCount: allAssets.length,
            itemBuilder: (context, index) {
              final asset = allAssets[index];
              // Utilise une clé unique pour chaque item basée sur l'objet Asset lui-même
              return _AssetEditorTile(
                key: ValueKey(asset),
                asset: asset,
                onChanged: _onDataChanged,
              );
            },
          ),
        ),
        if (_hasChanges)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                 ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_outlined),
                  label: const Text('Enregistrer'),
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler'),
                  onPressed: _resetLocalCopy,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// --- Widget interne pour gérer l'édition d'un seul actif ---

class _AssetEditorTile extends StatefulWidget {
  final Asset asset;
  final VoidCallback onChanged;

  const _AssetEditorTile({required Key key, required this.asset, required this.onChanged}) : super(key: key);

  @override
  State<_AssetEditorTile> createState() => _AssetEditorTileState();
}

class _AssetEditorTileState extends State<_AssetEditorTile> {
  late final TextEditingController _quantityController;
  late final TextEditingController _pruController;
  late final TextEditingController _priceController;
  late final TextEditingController _yieldController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.asset.quantity.toString());
    _pruController = TextEditingController(text: widget.asset.averagePrice.toStringAsFixed(2));
    _priceController = TextEditingController(text: widget.asset.currentPrice.toStringAsFixed(2));
    _yieldController = TextEditingController(text: (widget.asset.estimatedAnnualYield * 100).toStringAsFixed(2));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pruController.dispose();
    _priceController.dispose();
    _yieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.asset.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildEditableField(
                  label: 'Quantité',
                  controller: _quantityController,
                  onChanged: (value) {
                    widget.asset.quantity = double.tryParse(value) ?? widget.asset.quantity;
                    widget.onChanged();
                  },
                ),
                const SizedBox(width: 8),
                _buildEditableField(
                  label: 'PRU',
                  controller: _pruController,
                  onChanged: (value) {
                    widget.asset.averagePrice = double.tryParse(value) ?? widget.asset.averagePrice;
                    widget.onChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildEditableField(
                  label: 'Prix Actuel',
                  controller: _priceController,
                  onChanged: (value) {
                    widget.asset.currentPrice = double.tryParse(value) ?? widget.asset.currentPrice;
                    widget.onChanged();
                  },
                ),
                const SizedBox(width: 8),
                _buildEditableField(
                  label: 'Rdt. Ann. Est. (%)',
                  controller: _yieldController,
                  onChanged: (value) {
                    final percentage = double.tryParse(value);
                    if (percentage != null) {
                      widget.asset.estimatedAnnualYield = percentage / 100.0;
                    }
                    widget.onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
      ),
    );
  }
}
