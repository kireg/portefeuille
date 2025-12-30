import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/utils/isin_validator.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';

import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/widgets/inputs/app_dropdown.dart';
import 'package:portefeuille/core/Design_Center/widgets/inputs/app_text_field.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_card.dart';
import '_crowdfunding_fields.dart';

class AssetFields extends StatelessWidget {
  const AssetFields({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();
    final readState = context.read<TransactionFormState>();

    return Column(
      children: [
        AppDropdown<AssetType>(
          label: 'Type d\'actif',
          value: state.selectedAssetType,
          items: AssetType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (type) => readState.selectAssetType(type),
        ),
        const SizedBox(height: AppDimens.paddingM),

        // Champs standards (masqués pour le Crowdfunding)
        if (state.selectedAssetType != AssetType.RealEstateCrowdfunding) ...[
          AppTextField(
            controller: state.tickerController,
            label: 'Ticker ou ISIN',
            hint: 'AAPL, BTC...',
            prefixIcon: Icons.label_outline,
            textCapitalization: TextCapitalization.characters,
            suffixIcon: (state.isLoadingSearch && state.settingsProvider.isOnlineMode)
                ? const SizedBox(
              width: 20,
              height: 20,
              child: Center(
                  child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                  )
              ),
            )
                : null,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Requis';
              final cleaned = IsinValidator.cleanIsin(value);
              if (IsinValidator.looksLikeIsin(cleaned) && !IsinValidator.isValidIsinFormat(cleaned)) {
                return 'Format ISIN invalide';
              }
              return null;
            },
          ),

          // Suggestions de recherche
          if (state.suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.paddingS),
              child: AppCard(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.surfaceLight,
                child: SizedBox(
                  height: 150,
                  child: ListView.separated(
                    itemCount: state.suggestions.length,
                    separatorBuilder: (ctx, i) => Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final suggestion = state.suggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(suggestion.name, style: AppTypography.bodyBold),
                        subtitle: Text(
                          "${suggestion.ticker} • ${suggestion.exchange}",
                          style: AppTypography.caption,
                        ),
                        trailing: suggestion.price != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${suggestion.price} ${suggestion.currency}',
                                    style: AppTypography.bodyBold.copyWith(fontSize: 12),
                                  ),
                                ],
                              )
                            : Text(suggestion.currency, style: AppTypography.caption),
                        onTap: () => readState.onSuggestionSelected(suggestion, context),
                      );
                    },
                  ),
                ),
              ),
            )
          else if (!state.isLoadingSearch &&
              state.tickerController.text.trim().length >= 2 &&
              state.settingsProvider.isOnlineMode)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.paddingS),
              child: Text(
                'Aucun résultat trouvé.',
                style: AppTypography.caption.copyWith(color: AppColors.warning),
              ),
            ),

          const SizedBox(height: AppDimens.paddingM),
        ],

        AppTextField(
          controller: state.nameController,
          label: state.selectedAssetType == AssetType.RealEstateCrowdfunding 
              ? 'Nom du Projet' 
              : 'Nom de l\'actif',
          hint: state.selectedAssetType == AssetType.RealEstateCrowdfunding 
              ? 'Ex: Résidence Les Pins' 
              : 'Apple Inc.',
          textCapitalization: TextCapitalization.words,
          validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
        ),

        const SizedBox(height: AppDimens.paddingM),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                controller: state.priceCurrencyController,
                label: 'Devise',
                textCapitalization: TextCapitalization.characters,
                validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              flex: 3,
              child: AppTextField(
                controller: state.exchangeRateController,
                label: 'Taux (vers ${state.accountCurrency})',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,8}'))],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Invalide';
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimens.paddingM),

        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: state.quantityController,
                label: state.selectedAssetType == AssetType.RealEstateCrowdfunding 
                    ? 'Montant Investi' 
                    : 'Quantité',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,8}'))],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Invalide';
                  return null;
                },
              ),
            ),
            // Masquer le prix unitaire pour le Crowdfunding (on considère Qty = Montant, Prix = 1)
            if (state.selectedAssetType != AssetType.RealEstateCrowdfunding) ...[
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: AppTextField(
                  controller: state.priceController,
                  label: 'Prix unitaire',
                  suffixText: state.priceCurrencyController.text,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}'))],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requis';
                    if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Invalide';
                    return null;
                  },
                ),
              ),
            ],
          ],
        ),

        // Crowdfunding fields
        if (state.selectedAssetType == AssetType.RealEstateCrowdfunding)
          const CrowdfundingFields(),
      ],
    );
  }
}