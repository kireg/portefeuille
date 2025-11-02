import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/asset.dart';

class CorrectionTab extends StatefulWidget {
  const CorrectionTab({super.key});

  @override
  State<CorrectionTab> createState() => _CorrectionTabState();
}

class _CorrectionTabState extends State<CorrectionTab> {
  // TODO: Implémenter la logique de modification et de sauvegarde
  bool _hasChanges = false;

  void _onDataChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _saveChanges() {
    // TODO: Sauvegarder les modifications via le provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modifications enregistrées !')),
    );
    setState(() {
      _hasChanges = false;
    });
  }

  void _cancelChanges() {
    // TODO: Recharger les données originales depuis le provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modifications annulées.')),
    );
    setState(() {
      _hasChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = Provider.of<PortfolioProvider>(context).portfolio;
    final allAssets = portfolio?.institutions
            .expand((inst) => inst.accounts)
            .expand((acc) => acc.assets)
            .toList() ??
        [];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: allAssets.length,
            itemBuilder: (context, index) {
              final asset = allAssets[index];
              return _buildAssetEditorTile(asset);
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
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler'),
                  onPressed: _cancelChanges,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[300]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAssetEditorTile(Asset asset) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(asset.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildEditableField('Quantité', asset.quantity.toString()),
                const SizedBox(width: 8),
                _buildEditableField('PRU', asset.averagePrice.toStringAsFixed(2)),
                 const SizedBox(width: 8),
                _buildEditableField('Prix Actuel', asset.currentPrice.toStringAsFixed(2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, String initialValue) {
    return Expanded(
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) => _onDataChanged(),
      ),
    );
  }
}
