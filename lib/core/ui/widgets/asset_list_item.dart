// lib/core/ui/widgets/asset_list_item.dart
// Centralized AssetListItem moved from features/03_overview/ui/widgets

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:shimmer/shimmer.dart';

class AssetListItem extends StatelessWidget {
  final Asset asset;
  /// La devise native du compte parent (ex: "EUR")
  final String accountCurrency;
  /// La devise de base de l'utilisateur (ex: "USD")
  final String baseCurrency;
  const AssetListItem({
    super.key,
    required this.asset,
    required this.accountCurrency,
    required this.baseCurrency,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<PortfolioProvider>();
    final isProcessing = provider.isProcessingInBackground;

    final totalValueConverted = provider.getConvertedAssetTotalValue(asset.id);
    final pnlConverted = provider.getConvertedAssetPL(asset.id);

    final pnlPercentage = asset.profitAndLossPercentage;
    final pnlColor =
    pnlConverted >= 0 ? Colors.green.shade400 : Colors.red.shade400;
    return ListTile(
      dense: true,
      title: Text(
        asset.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          children: <TextSpan>[
            // CORRECTION ICI : Suppression des \ devant les $
            TextSpan(
                text:
                '${asset.quantity} x ${CurrencyFormatter.format(asset.averagePrice, asset.priceCurrency)}'),
            if (asset.estimatedAnnualYield > 0)
              TextSpan(
                // CORRECTION ICI : Suppression des \ devant les $
                text:
                '  •  Rdt. Annuel Est. ${NumberFormat.percentPattern().format(asset.estimatedAnnualYield)}',
                style: TextStyle(color: Colors.deepPurple[400]),
              ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 100,
        child: isProcessing
            ? _buildTrailingShimmer(theme)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(totalValueConverted, baseCurrency),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              // CORRECTION ICI : Suppression des \ devant les $
              '${CurrencyFormatter.format(pnlConverted, baseCurrency)} (${(pnlPercentage * 100).toStringAsFixed(2)}%)',
              style: theme.textTheme.bodySmall?.copyWith(color: pnlColor),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingShimmer(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Shimmer.fromColors(
          baseColor: theme.colorScheme.surface,
          highlightColor: theme.colorScheme.surfaceContainerHighest,
          child: Container(
            width: 70,
            height: theme.textTheme.bodyLarge?.fontSize ?? 16,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Shimmer.fromColors(
          baseColor: theme.colorScheme.surface,
          highlightColor: theme.colorScheme.surfaceContainerHighest,
          child: Container(
            width: 90,
            height: theme.textTheme.bodySmall?.fontSize ?? 12,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}