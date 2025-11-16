// lib/features/07_management/ui/widgets/form_sections/_asset_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/utils/isin_validator.dart';
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
            labelText: 'Ticker ou ISIN *',
            hintText: 'Ex: AAPL ou US0378331005',
            helperText:
                'Saisissez un ticker (AAPL) ou un code ISIN (12 caractères)',
            border: const OutlineInputBorder(),
            suffixIcon:
                state.isLoadingSearch && state.settingsProvider.isOnlineMode
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ticker ou ISIN requis';
            }
            // Si la valeur ressemble à un ISIN, valider le format
            final cleaned = IsinValidator.cleanIsin(value);
            if (IsinValidator.looksLikeIsin(cleaned)) {
              if (!IsinValidator.isValidIsinFormat(cleaned)) {
                return 'Format ISIN invalide (attendu: 2 lettres + 10 alphanumériques)';
              }
            }
            return null;
          },
        ),
        // Affichage des suggestions ou message "Aucun résultat"
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
                        "${suggestion.ticker} (${suggestion.exchange})"
                        "${suggestion.currency.isNotEmpty && suggestion.currency != '???' ? ' - Devise: ${suggestion.currency}' : ' - Devise: non disponible'}"
                        "${suggestion.isin != null && suggestion.isin!.isNotEmpty ? ' • ISIN: ${suggestion.isin}' : ''}"),
                    onTap: () =>
                        readState.onSuggestionSelected(suggestion, context),
                  );
                },
              ),
            ),
          )
        else if (!state.isLoadingSearch &&
            state.tickerController.text.trim().length >= 2 &&
            state.settingsProvider.isOnlineMode)
          // Message "Aucun résultat" si recherche effectuée sans résultats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.search_off,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucun résultat trouvé pour "${state.tickerController.text.trim()}". Vérifiez l\'orthographe ou saisissez manuellement.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
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
                  if (value == null || value.isEmpty)
                    return 'Requis (1.0 si identique)';
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
