// lib/features/04_summary/ui/dialogs/asset_dialogs.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/data/models/aggregated_asset.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

class AssetDialogs {

  static void showEditYieldDialog(
      BuildContext context, AggregatedAsset asset, PortfolioProvider provider) {
    final controller = TextEditingController(
        text: (asset.estimatedAnnualYield * 100).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Modifier rendement', style: AppTypography.h3),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTypography.body,
          decoration: InputDecoration(
            labelText: 'Rendement annuel (%)',
            labelStyle: AppTypography.caption,
            suffixText: '%',
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textTertiary)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuler',
                style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final enteredValue =
                  double.tryParse(controller.text.replaceAll(',', '.')) ??
                      (asset.estimatedAnnualYield * 100);
              final newYieldAsDecimal = enteredValue / 100.0;
              provider.updateAssetYield(asset.ticker, newYieldAsDecimal);
              Navigator.of(ctx).pop();
            },
            child: Text('Sauvegarder',
                style: AppTypography.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  static void showEditPriceDialog(BuildContext context, AggregatedAsset asset,
      PortfolioProvider provider) {

    final nativeCurrency = asset.assetCurrency;
    final nativePrice = asset.metadata?.currentPrice ?? asset.currentPrice;
    final controller = TextEditingController(text: nativePrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Modifier prix', style: AppTypography.h3),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTypography.body,
          decoration: InputDecoration(
            labelText: 'Prix actuel ($nativeCurrency)',
            labelStyle: AppTypography.caption,
            suffixText: nativeCurrency,
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textTertiary)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuler',
                style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final newPrice =
                  double.tryParse(controller.text.replaceAll(',', '.')) ??
                      nativePrice;
              provider.updateAssetPrice(asset.ticker, newPrice,
                  currency: nativeCurrency);
              Navigator.of(ctx).pop();
            },
            child: Text('Sauvegarder',
                style: AppTypography.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}