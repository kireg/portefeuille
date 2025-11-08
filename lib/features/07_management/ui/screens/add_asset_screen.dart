// lib/features/07_management/ui/screens/add_asset_screen.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddAssetScreen extends StatefulWidget {
  final String accountId;
  const AddAssetScreen({super.key, required this.accountId});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _nameController = TextEditingController();
  final _tickerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _avgPriceController = TextEditingController();
  final _currentPriceController = TextEditingController();
  final _yieldController = TextEditingController(text: "0.0");

  @override
  void dispose() {
    _nameController.dispose();
    _tickerController.dispose();
    _quantityController.dispose();
    _avgPriceController.dispose();
    _currentPriceController.dispose();
    _yieldController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newAsset = Asset(
        id: _uuid.v4(),
        name: _nameController.text,
        ticker: _tickerController.text.toUpperCase(),
        quantity: double.tryParse(_quantityController.text) ?? 0,
        averagePrice: double.tryParse(_avgPriceController.text) ?? 0,
        currentPrice: double.tryParse(_currentPriceController.text) ?? 0,
        estimatedAnnualYield:
        (double.tryParse(_yieldController.text) ?? 0) / 100.0,
      );

      Provider.of<PortfolioProvider>(context, listen: false)
          .addAsset(widget.accountId, newAsset);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    // MODIFIÉ : Retrait du Scaffold
    return SingleChildScrollView(
      // MODIFIÉ : Padding ajusté
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
          children: [
            Text(
              'Ajouter un Actif',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nom (ex: Apple)'),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tickerController,
              decoration:
              const InputDecoration(labelText: 'Ticker (ex: AAPL)'),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantité'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _avgPriceController,
              decoration: const InputDecoration(
                  labelText: 'Prix de Revient Unitaire (PRU)'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentPriceController,
              decoration: const InputDecoration(labelText: 'Prix Actuel'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _yieldController,
              decoration: const InputDecoration(
                  labelText: 'Rendement Annuel Estimé (%)',
                  suffixText: '%'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Enregistrer'),
            )
          ],
        ),
      ),
    );
  }
}