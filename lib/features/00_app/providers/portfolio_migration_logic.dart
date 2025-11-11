// lib/features/00_app/providers/portfolio_migration_logic.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';
// NOUVEL IMPORT (Correction Erreur 1)
import 'package:portefeuille/core/data/models/asset_type.dart';

class PortfolioMigrationLogic {
  final PortfolioRepository repository;
  // MODIFIÉ : Retrait de 'final' (Correction Erreurs 2/3)
  SettingsProvider settingsProvider;
  final Uuid uuid;

  PortfolioMigrationLogic({
    required this.repository,
    required this.settingsProvider,
    required this.uuid,
  });

  /// Convertit les champs `stale_` en transactions.
  Future<void> runDataMigrationV1(List<Portfolio> portfolios) async {
    final bool needsMigration = portfolios.any((p) => p.institutions
        .any((i) => i.accounts.any((a) =>
    a.stale_cashBalance != null || (a.stale_assets?.isNotEmpty ?? false))));
    if (!needsMigration) {
      debugPrint("Migration V1 : Aucune donnée périmée trouvée. Ignoré.");
      await settingsProvider.setMigrationV1Done();
      return;
    }

    debugPrint("--- DÉBUT MIGRATION V1 ---");
    final List<Transaction> newTransactions = [];
    for (final portfolio in portfolios) {
      bool portfolioNeedsSave = false;
      for (final inst in portfolio.institutions) {
        for (final acc in inst.accounts) {
          final migrationDate = DateTime(2020, 1, 1);
          double totalCashFromAssets = 0.0;

          if (acc.stale_assets != null && acc.stale_assets!.isNotEmpty) {
            for (final asset in acc.stale_assets!) {
              final qty = asset.stale_quantity;
              final pru = asset.stale_averagePrice;
              if (qty != null && pru != null && qty > 0) {
                totalCashFromAssets += (qty * pru);
              }
            }
          }

          final totalCashNeeded = (acc.stale_cashBalance ?? 0.0) + totalCashFromAssets;
          if (totalCashNeeded > 0) {
            debugPrint(
                "Migration : Ajout Dépôt initial de ${totalCashNeeded.toStringAsFixed(2)}€ pour ${acc.name} "
                    "(Liquidités: ${acc.stale_cashBalance?.toStringAsFixed(2) ?? '0.00'}€ + Actifs: ${totalCashFromAssets.toStringAsFixed(2)}€)");
            newTransactions.add(Transaction(
              id: uuid.v4(),
              accountId: acc.id,
              type: TransactionType.Deposit,
              date: migrationDate,
              amount: totalCashNeeded,
              notes: "Migration v1 - Dépôt initial (Solde: ${acc.stale_cashBalance?.toStringAsFixed(2) ?? '0.00'}€)",
            ));
            acc.stale_cashBalance = null;
            portfolioNeedsSave = true;
          }

          if (acc.stale_assets != null && acc.stale_assets!.isNotEmpty) {
            debugPrint(
                "Migration : ${acc.stale_assets!.length} actifs pour ${acc.name}");
            for (final asset in acc.stale_assets!) {
              final qty = asset.stale_quantity;
              final pru = asset.stale_averagePrice;

              if (qty != null && pru != null && qty > 0) {
                final totalCost = qty * pru;
                // MODIFIÉ : Utilisation de 'displayName' (Correction Erreur 1)
                debugPrint(
                    "Migration : Actif ${asset.ticker} (Qty: $qty, PRU: ${pru.toStringAsFixed(2)}€, Type: ${asset.type.displayName})");
                newTransactions.add(Transaction(
                  id: uuid.v4(),
                  accountId: acc.id,
                  type: TransactionType.Buy,
                  date: migrationDate,
                  assetTicker: asset.ticker,
                  assetName: asset.name,
                  assetType: asset.type,
                  quantity: qty,
                  price: pru,
                  amount: -totalCost,
                  fees: 0,
                  notes: "Migration v1 - Achat ${asset.ticker}",
                ));
              }
            }
            acc.stale_assets = null;
            portfolioNeedsSave = true;
          }
        }
      }

      if (portfolioNeedsSave) {
        debugPrint("Migration : Nettoyage du portefeuille ${portfolio.name}");
        await repository.savePortfolio(portfolio);
      }
    }

    debugPrint("Migration : Sauvegarde de ${newTransactions.length} transactions...");
    for (final tx in newTransactions) {
      await repository.saveTransaction(tx);
    }

    await settingsProvider.setMigrationV1Done();
    debugPrint("--- FIN MIGRATION V1 : Rechargement des données ---");
  }
}