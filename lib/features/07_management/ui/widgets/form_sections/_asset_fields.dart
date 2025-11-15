// lib/features/07_management/ui/widgets/form_sections/_asset_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:provider/provider.dart';

class AssetFields extends StatelessWidget {
  const AssetFields({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();
    final readState = context.read<TransactionFormState>();
    final theme = Theme.of(context);

    return Column(
      children: [
        DropdownButtonFormField<AssetType>(
          value: state.selectedAssetType,
          items: AssetType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (type) => readState.selectAssetType(type),
          decoration: const InputDecoration(
            labelText: 'Type d\'actif *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: state.tickerController,
          decoration: InputDecoration(
            labelText: 'Ticker (ex: AAPL) *',
            border: const OutlineInputBorder(),
            suffixIcon: state.isLoadingSearch && state.settingsProvider.isOnlineMode
                ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
                : null,
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) =>
          (value == null || value.isEmpty) ? 'Ticker requis' : null,
        ),
        if (state.suggestions.isNotEmpty)
          SizedBox(
            height: 150,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: state.suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = state.suggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(suggestion.name),
                    subtitle: Text(
                        "${suggestion.ticker} (${suggestion.exchange}) - Devise: ${suggestion.currency}"),
                    onTap: () => readState.onSuggestionSelected(suggestion, context),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextFormField(
          controller: state.nameController,
          decoration: const InputDecoration(
            labelText: 'Nom de l\'actif (ex: Apple Inc.) *',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
          (value == null || value.isEmpty) ? 'Nom requis' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: state.priceCurrencyController,
                decoration: const InputDecoration(
                  labelText: 'Devise Prix *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: state.exchangeRateController,
                decoration: InputDecoration(
                  labelText: 'Taux (vers ${state.accountCurrency}) *',
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,8}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis (1.0 si identique)';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: state.quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité *',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,8}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: state.priceController,
                decoration: InputDecoration(
                  labelText: 'Prix unitaire *',
                  border: const OutlineInputBorder(),
                  suffixText: state.priceCurrencyController.text,
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}