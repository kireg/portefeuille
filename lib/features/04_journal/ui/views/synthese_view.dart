// lib/features/04_journal/ui/views/synthese_view.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

class AggregatedAsset {
  final String ticker;
  final String name;
  final double quantity;
  final double averagePrice;
  final double currentPrice;
  final double estimatedAnnualYield;

  AggregatedAsset({
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.estimatedAnnualYield,
  });

  double get totalValue => quantity * currentPrice;
  double get profitAndLoss => (currentPrice - averagePrice) * quantity;
}

class SyntheseView extends StatefulWidget {
  const SyntheseView({super.key});

  @override
  State<SyntheseView> createState() => _SyntheseViewState();
}

class _SyntheseViewState extends State<SyntheseView> {
  List<AggregatedAsset> _aggregateAssets(PortfolioProvider provider) {
    final allAssets = provider.activePortfolio?.institutions
            .expand((inst) => inst.accounts)
            .expand((acc) => acc.assets)
            .toList() ??
        [];

    if (allAssets.isEmpty) return [];

    final Map<String, List<Asset>> groupedByTicker = {};
    for (final asset in allAssets) {
      (groupedByTicker[asset.ticker] ??= []).add(asset);
    }

    final List<AggregatedAsset> aggregatedList = [];

    groupedByTicker.forEach((ticker, assets) {
      if (assets.isEmpty) return;

      final firstAsset = assets.first;
      double totalQuantity = 0;
      double totalCost = 0;

      for (final asset in assets) {
        totalQuantity += asset.quantity;
        totalCost += (asset.quantity * asset.averagePrice);
      }

      final double aggregatedAveragePrice =
          (totalQuantity > 0) ? totalCost / totalQuantity : 0.0;

      if (totalQuantity > 0) {
        aggregatedList.add(
          AggregatedAsset(
            ticker: ticker,
            name: firstAsset.name,
            quantity: totalQuantity,
            averagePrice: aggregatedAveragePrice,
            currentPrice: firstAsset.currentPrice,
            estimatedAnnualYield: firstAsset.estimatedAnnualYield,
          ),
        );
      }
    });

    aggregatedList.sort((a, b) {
      final bValue = b.quantity * b.currentPrice;
      final aValue = a.quantity * a.currentPrice;
      return bValue.compareTo(aValue);
    });

    return aggregatedList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final aggregatedAssets = _aggregateAssets(provider);

        if (provider.activePortfolio == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (aggregatedAssets.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppTheme.buildEmptyStateCard(
              context: context,
              icon: Icons.pie_chart_outline,
              title: 'Aucun actif à agréger',
              subtitle:
                  'Les actifs apparaîtront ici une fois que vous aurez ajouté des transactions.',
              buttonLabel: 'Ajouter une transaction',
              onPressed: () {
                // Navigation vers l'ajout de transaction
                // Vous pouvez adapter selon votre navigation
              },
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppTheme.buildStyledCard(
            context: context,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.buildSectionHeader(
                  context: context,
                  icon: Icons.account_balance_outlined,
                  title: 'Synthèse des Actifs',
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              columnSpacing: 20.0,
                              headingRowColor: WidgetStateProperty.all(
                                theme.colorScheme.surfaceContainerHighest
                                    .withOpacity(0.3),
                              ),
                              columns: const [
                                DataColumn(label: Text('Statut')),
                                DataColumn(label: Text('Actif')),
                                DataColumn(
                                    label: Text('Quantité'), numeric: true),
                                DataColumn(label: Text('PRU'), numeric: true),
                                DataColumn(
                                    label: Text('Prix actuel'), numeric: true),
                                DataColumn(
                                    label: Text('Valeur'), numeric: true),
                                DataColumn(label: Text('P/L'), numeric: true),
                                DataColumn(
                                    label: Text('Rendement %'), numeric: true),
                              ],
                              rows: aggregatedAssets.map((asset) {
                                final pnl = asset.profitAndLoss;
                                final pnlColor = pnl >= 0
                                    ? Colors.green.shade400
                                    : Colors.red.shade400;

                                // Récupérer les métadonnées pour obtenir le statut de synchro
                                final metadata =
                                    provider.allMetadata[asset.ticker];
                                final syncStatus =
                                    metadata?.syncStatus ?? SyncStatus.never;
                                final tooltipMessage =
                                    _buildTooltipMessage(syncStatus, metadata);

                                return DataRow(
                                  cells: [
                                    // Nouvelle cellule : Statut de synchronisation
                                    DataCell(
                                      Tooltip(
                                        message: tooltipMessage,
                                        child: Text(
                                          syncStatus.icon,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(asset.name,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              )),
                                          Text(asset.ticker,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: Colors.grey,
                                              )),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(
                                        asset.quantity.toStringAsFixed(2))),
                                    DataCell(Text(CurrencyFormatter.format(
                                        asset.averagePrice))),
                                    DataCell(
                                      InkWell(
                                        onTap: () => _showEditPriceDialog(
                                            context, asset, provider),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              CurrencyFormatter.format(
                                                  asset.currentPrice),
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(
                                        CurrencyFormatter.format(
                                            asset.totalValue),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ))),
                                    DataCell(
                                      Text(
                                        CurrencyFormatter.format(pnl),
                                        style: TextStyle(color: pnlColor),
                                      ),
                                    ),
                                    DataCell(
                                      InkWell(
                                        onTap: () => _showEditYieldDialog(
                                            context, asset, provider),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${(asset.estimatedAnnualYield * 100).toStringAsFixed(2)} %',
                                              style: TextStyle(
                                                  color: theme
                                                      .colorScheme.primary),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.edit,
                                                size: 16,
                                                color:
                                                    theme.colorScheme.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditYieldDialog(
      BuildContext context, AggregatedAsset asset, PortfolioProvider provider) {
    final controller = TextEditingController(
        text: (asset.estimatedAnnualYield * 100).toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier le rendement de ${asset.ticker}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Rendement annuel estimé (%)',
            hintText: 'Ex: 3.5',
            suffixText: '%',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final enteredValue =
                  double.tryParse(controller.text.replaceAll(',', '.')) ??
                      (asset.estimatedAnnualYield * 100);
              final newYieldAsDecimal = enteredValue / 100.0;
              provider.updateAssetYield(asset.ticker, newYieldAsDecimal);
              Navigator.of(ctx).pop();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(
      BuildContext context, AggregatedAsset asset, PortfolioProvider provider) {
    final controller =
        TextEditingController(text: asset.currentPrice.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier le prix de ${asset.ticker}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Prix actuel (€)',
            hintText: 'Ex: 451.98',
            suffixText: '€',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final newPrice =
                  double.tryParse(controller.text.replaceAll(',', '.')) ??
                      asset.currentPrice;
              provider.updateAssetPrice(asset.ticker, newPrice);
              Navigator.of(ctx).pop();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  /// Construit un message de tooltip détaillé selon le statut
  String _buildTooltipMessage(SyncStatus status, metadata) {
    switch (status) {
      case SyncStatus.synced:
        final lastUpdate = metadata?.lastUpdated;
        final source = metadata?.lastSyncSource ?? 'API';
        if (lastUpdate != null) {
          final date =
              '${lastUpdate.day}/${lastUpdate.month}/${lastUpdate.year} ${lastUpdate.hour}:${lastUpdate.minute.toString().padLeft(2, '0')}';
          return '✅ Synchronisé avec succès\nSource: $source\nDernière mise à jour: $date';
        }
        return '✅ Synchronisé avec succès\nSource: $source';

      case SyncStatus.error:
        final errorMsg = metadata?.syncErrorMessage ?? 'Erreur inconnue';
        return '⚠️ Erreur de synchronisation\n${errorMsg.length > 100 ? '${errorMsg.substring(0, 100)}...' : errorMsg}\n\nConsultez la Vue d\'ensemble pour plus de détails';

      case SyncStatus.manual:
        final lastUpdate = metadata?.lastUpdated;
        if (lastUpdate != null) {
          final date =
              '${lastUpdate.day}/${lastUpdate.month}/${lastUpdate.year}';
          return '✏️ Prix saisi manuellement\nDernière modification: $date\n\nLe prix ne sera pas remplacé automatiquement';
        }
        return '✏️ Prix saisi manuellement\nLe prix ne sera pas remplacé automatiquement';

      case SyncStatus.never:
        return '⭕ Jamais synchronisé\nAucune tentative de récupération automatique du prix\n\nLancez une synchronisation depuis la Vue d\'ensemble';

      case SyncStatus.unsyncable:
        return '🚫 Non synchronisable\nCet actif ne peut pas être synchronisé automatiquement\n(fonds en euros, produit non coté)\n\nSaisissez le prix manuellement en cliquant sur "Prix actuel"';
    }
  }
}
