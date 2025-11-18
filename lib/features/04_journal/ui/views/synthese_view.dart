// lib/features/04_journal/ui/views/synthese_view.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
// NOUVEL IMPORT
import 'package:portefeuille/core/data/models/aggregated_asset.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
// FIN NOUVEL IMPORT
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';
// --- (Le modèle AggregatedAsset a été déplacé dans core/data/models) ---

class SyntheseView extends StatefulWidget {
  const SyntheseView({super.key});
  @override
  State<SyntheseView> createState() => _SyntheseViewState();
}

class _SyntheseViewState extends State<SyntheseView> {
  // --- (La logique _aggregateAssets est maintenant dans le PortfolioProvider) ---

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    // RÉCUPÉRER LA DEVISE DE BASE
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final baseCurrency = provider.currentBaseCurrency;
        final aggregatedAssets = provider.aggregatedAssets;

        // --- MODIFIÉ ---
        final isProcessing = provider.isProcessingInBackground;
        // --- FIN MODIFICATION ---

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
                // TODO: Remplacer par la navigation vers l'ajout de transaction
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
                  // --- MODIFIÉ : Stack pour l'overlay ---
                  child: Stack(
                    children: [
                      SingleChildScrollView(
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
                                        label: Text('Quantité'),
                                        numeric: true),
                                    DataColumn(
                                        label: Text('PRU'), numeric: true),
                                    DataColumn(
                                        label: Text('Prix actuel'),
                                        numeric: true),
                                    DataColumn(
                                        label: Text('Valeur'), numeric: true),
                                    DataColumn(
                                        label: Text('P/L'), numeric: true),
                                    DataColumn(
                                        label: Text('Rendement %'),
                                        numeric: true),
                                  ],
                                  rows: aggregatedAssets.map((asset) {
                                    // ▼▼▼ MODIFIÉ : Toutes les valeurs sont déjà en devise de base ▼▼▼
                                    final pnl = asset.profitAndLoss;
                                    final pnlColor = pnl >= 0
                                        ? Colors.green.shade400
                                        : Colors.red.shade400;
                                    // La devise d'affichage principale est la devise de BASE
                                    final String displayCurrency =
                                        baseCurrency;
                                    final syncStatus = asset.syncStatus;
                                    final tooltipMessage =
                                    _buildTooltipMessage(
                                        syncStatus,
                                        asset.metadata,
                                        asset.assetCurrency);
                                    // ▲▲▲ FIN MODIFICATION ▲▲▲

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Tooltip(
                                            message: tooltipMessage,
                                            child: Text(
                                              syncStatus.icon,
                                              style:
                                              const TextStyle(fontSize: 18),
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
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  )),
                                              Text(asset.ticker,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: Colors.grey,
                                                  )),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(
                                          // TODO: Formatter avec 'formatWithoutSymbol'
                                            asset.quantity.toStringAsFixed(2))),
                                        DataCell(Text(
                                          // Affiche le PRU en devise de BASE
                                            CurrencyFormatter.format(
                                                asset.averagePrice,
                                                displayCurrency))),
                                        DataCell(
                                          InkWell(
                                            onTap: () => _showEditPriceDialog(
                                                context,
                                                asset,
                                                provider,
                                                // Le prix est édité dans sa devise NATIVE
                                                asset.assetCurrency),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  // Affiche le prix en devise de BASE
                                                  CurrencyFormatter.format(
                                                      asset.currentPrice,
                                                      displayCurrency),
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color:
                                                  theme.colorScheme.primary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(
                                          // Affiche la valeur en devise de BASE
                                            CurrencyFormatter.format(
                                                asset.totalValue,
                                                displayCurrency),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ))),
                                        DataCell(
                                          Text(
                                            // Affiche la P/L en devise de BASE
                                            CurrencyFormatter.format(
                                                pnl, displayCurrency),
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
                                                    color: theme
                                                        .colorScheme.primary),
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
                      // --- NOUVEAU : Overlay de chargement ---
                      if (isProcessing)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                              theme.scaffoldBackgroundColor.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Recalcul des devises...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // --- FIN NOUVEAU ---
                    ],
                  ),
                  // --- FIN Stack ---
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

  // MODIFIÉ : Accepte la devise NATIVE de l'actif pour l'édition
  void _showEditPriceDialog(BuildContext context, AggregatedAsset asset,
      PortfolioProvider provider, String nativeCurrency) {
    // Doit trouver le prix natif actuel dans les métadonnées
    final nativePrice =
        asset.metadata?.currentPrice ?? asset.currentPrice;

    final controller =
    TextEditingController(text: nativePrice.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier le prix de ${asset.ticker}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Prix actuel ($nativeCurrency)',
            hintText: 'Ex: 451.98',
            suffixText: nativeCurrency,
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
                      nativePrice;
              // MODIFIÉ : Passe la devise NATIVE à la méthode de mise à jour
              provider.updateAssetPrice(asset.ticker, newPrice,
                  currency: nativeCurrency);
              Navigator.of(ctx).pop();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  // MODIFIÉ : Accepte la devise native
  String _buildTooltipMessage(
      SyncStatus status, AssetMetadata? metadata, String nativeCurrency) {
    switch (status) {
      case SyncStatus.synced:
        final lastUpdate = metadata?.lastUpdated;
        final source = metadata?.lastSyncSource ?? 'API';
        if (lastUpdate != null) {
          final date =
              '${lastUpdate.day}/${lastUpdate.month}/${lastUpdate.year} ${lastUpdate.hour}:${lastUpdate.minute.toString().padLeft(2, '0')}';
          return '✅ Synchronisé avec succès ($nativeCurrency)\nSource: $source\nDernière mise à jour: $date';
        }
        return '✅ Synchronisé avec succès ($nativeCurrency)\nSource: $source';
      case SyncStatus.error:
        final errorMsg = metadata?.syncErrorMessage ?? 'Erreur inconnue';
        return '⚠️ Erreur de synchronisation\n${errorMsg.length > 100 ? '${errorMsg.substring(0, 100)}...' : errorMsg}\n\nConsultez la Vue d\'ensemble pour plus de détails';
      case SyncStatus.manual:
        final lastUpdate = metadata?.lastUpdated;
        if (lastUpdate != null) {
          final date =
              '${lastUpdate.day}/${lastUpdate.month}/${lastUpdate.year}';
          return '✏️ Prix manuel ($nativeCurrency)\nDernière modification: $date\n\nLe prix ne sera pas remplacé automatiquement';
        }
        return '✏️ Prix manuel ($nativeCurrency)\nLe prix ne sera pas remplacé automatiquement';
      case SyncStatus.never:
        return '⭕ Jamais synchronisé\nAucune tentative de récupération automatique du prix\n\nLancez une synchronisation depuis la Vue d\'ensemble';
      case SyncStatus.unsyncable:
        return '🚫 Non synchronisable ($nativeCurrency)\nCet actif ne peut pas être synchronisé automatiquement\n(fonds en euros, produit non coté)\n\nSaisissez le prix manuellement en cliquant sur "Prix actuel"';
    }
  }
}