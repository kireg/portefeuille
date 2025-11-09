// lib/features/04_journal/ui/views/synthese_view.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset.dart';
// import 'package:portefeuille/core/data/models/asset_type.dart'; // Plus nécessaire ici
// import 'package:portefeuille/core/data/models/transaction.dart'; // Plus nécessaire ici
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';
// import 'package:uuid/uuid.dart'; // <--- SUPPRIMÉ

// Classe temporaire pour l'agrégation
class AggregatedAsset {
  final String ticker;
  final String name;
  final double quantity;
  final double averagePrice; // PRU agrégé
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
  // --- MÉTHODE ENTIÈREMENT OPTIMISÉE ---
  /// Logique d'agrégation des actifs
  List<AggregatedAsset> _aggregateAssets(PortfolioProvider provider) {
    // 1. Aplatir tous les actifs (qui contiennent déjà P/L, PRU, Prix)
    //    de tous les comptes.
    final allAssets = provider.activePortfolio?.institutions
        .expand((inst) => inst.accounts)
        .expand((acc) => acc.assets) // Utilise le getter 'assets'
        .toList() ??
        [];

    if (allAssets.isEmpty) return [];

    // 2. Grouper les actifs par ticker
    final Map<String, List<Asset>> groupedByTicker = {};
    for (final asset in allAssets) {
      (groupedByTicker[asset.ticker] ??= []).add(asset);
    }

    final List<AggregatedAsset> aggregatedList = [];

    // 3. Agréger les métriques pour chaque ticker
    groupedByTicker.forEach((ticker, assets) {
      if (assets.isEmpty) return;

      final firstAsset = assets.first;
      double totalQuantity = 0;
      double totalCost = 0; // Somme de (Quantité * PRU) pour la pondération

      for (final asset in assets) {
        totalQuantity += asset.quantity;
        totalCost += (asset.quantity * asset.averagePrice);
      }

      // Calculer le PRU pondéré agrégé
      final double aggregatedAveragePrice =
      (totalQuantity > 0) ? totalCost / totalQuantity : 0.0;

      // N'ajoute pas l'actif si la quantité totale est nulle
      if (totalQuantity > 0) {
        aggregatedList.add(
          AggregatedAsset(
            ticker: ticker,
            name: firstAsset.name, // Le nom est le même
            quantity: totalQuantity,
            averagePrice: aggregatedAveragePrice,
            currentPrice: firstAsset.currentPrice, // Le prix est le même
            estimatedAnnualYield:
            firstAsset.estimatedAnnualYield, // Le rendement est le même
          ),
        );
      }
    });

    // Trier par valeur totale (calculée à partir des données agrégées)
    aggregatedList.sort((a, b) {
      final bValue = b.quantity * b.currentPrice;
      final aValue = a.quantity * a.currentPrice;
      return bValue.compareTo(aValue);
    });

    return aggregatedList;
  }
  // --- FIN DE L'OPTIMISATION ---

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        // Force le rebuild en accédant au timestamp
        final _ = provider.lastUpdateTimestamp;

        final aggregatedAssets = _aggregateAssets(provider);

        // Vérification de présence de portfolio
        if (provider.activePortfolio == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (aggregatedAssets.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun actif à agréger',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // 5. Construire le DataTable
        // MODIFIÉ : Utilisation de LayoutBuilder pour forcer la largeur maximale
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  // Force le DataTable à prendre au moins la largeur de l'écran
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 20.0,
                    columns: const [
                      DataColumn(label: Text('Actif')),
                      DataColumn(label: Text('Quantité'), numeric: true),
                      DataColumn(label: Text('PRU'), numeric: true),
                      DataColumn(label: Text('Prix actuel'), numeric: true),
                      DataColumn(label: Text('Valeur'), numeric: true),
                      DataColumn(label: Text('P/L'), numeric: true),
                      DataColumn(label: Text('Rendement %'), numeric: true),
                    ],
                    rows: aggregatedAssets.map((asset) {
                      final pnl = asset.profitAndLoss;
                      final pnlColor =
                      pnl >= 0 ? Colors.green.shade400 : Colors.red.shade400;

                      return DataRow(
                        cells: [
                          // Actif
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(asset.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(asset.ticker,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          // Quantité
                          DataCell(Text(asset.quantity.toStringAsFixed(2))),
                          // PRU
                          DataCell(
                              Text(CurrencyFormatter.format(asset.averagePrice))),
                          // Prix actuel (ÉDITABLE)
                          DataCell(
                            InkWell(
                              onTap: () =>
                                  _showEditPriceDialog(context, asset, provider),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(asset.currentPrice),
                                    style: TextStyle(
                                      color: asset.currentPrice > 0
                                          ? Colors.blue
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: asset.currentPrice > 0
                                        ? Colors.blue
                                        : Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Valeur
                          DataCell(Text(CurrencyFormatter.format(asset.totalValue),
                              style:
                              const TextStyle(fontWeight: FontWeight.bold))),
                          // P/L
                          DataCell(
                            Text(
                              CurrencyFormatter.format(pnl),
                              style: TextStyle(color: pnlColor),
                            ),
                          ),
                          // Rendement annuel estimé (ÉDITABLE)
                          DataCell(
                            InkWell(
                              onTap: () =>
                                  _showEditYieldDialog(context, asset, provider),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${asset.estimatedAnnualYield.toStringAsFixed(2)} %',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit,
                                      size: 16, color: Colors.blue),
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
        );
      },
    );
  }

  /// Affiche le dialogue pour éditer le rendement annuel estimé
  void _showEditYieldDialog(
      BuildContext context, AggregatedAsset asset, PortfolioProvider provider) {
    final controller =
    TextEditingController(text: asset.estimatedAnnualYield.toStringAsFixed(2));
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
          TextButton(
            onPressed: () {
              final newYield = double.tryParse(controller.text) ??
                  asset.estimatedAnnualYield;
              provider.updateAssetYield(asset.ticker, newYield);
              Navigator.of(ctx).pop();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialogue pour éditer le prix actuel
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
          TextButton(
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
}