// lib/features/00_app/providers/portfolio_migration_logic.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

class PortfolioMigrationLogic {
  final PortfolioRepository repository;
  SettingsProvider settingsProvider;
  final Uuid uuid;

  PortfolioMigrationLogic({
    required this.repository,
    required this.settingsProvider,
    required this.uuid,
  });

  /// Convertit les champs `stale_` en transactions (Migration V1).
  Future<void> runDataMigrationV1(List<Portfolio> portfolios) async {
    final bool needsMigration = portfolios.any((p) => p.institutions.any((i) =>
        i.accounts.any((a) =>
            a.stale_cashBalance != null ||
            (a.stale_assets?.isNotEmpty ?? false))));
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

          final totalCashNeeded =
              (acc.stale_cashBalance ?? 0.0) + totalCashFromAssets;
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
              notes:
                  "Migration v1 - Dépôt initial (Solde: ${acc.stale_cashBalance?.toStringAsFixed(2) ?? '0.00'}€)",
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

    debugPrint(
        "Migration : Sauvegarde de ${newTransactions.length} transactions...");
    for (final tx in newTransactions) {
      await repository.saveTransaction(tx);
    }

    await settingsProvider.setMigrationV1Done();
    debugPrint("--- FIN MIGRATION V1 : Rechargement des données ---");
  }

  // --- NOUVELLE MÉTHODE ---
  /// Met à jour les données V1 (sans devise) vers V2 (avec devise).
  /// Suppose que toutes les données existantes sont en EUR.
  Future<void> runDataMigrationV2() async {
    debugPrint("--- DÉBUT MIGRATION V2 (Devises) ---");

    // 1. Mettre à jour les Comptes (définir currency = 'EUR' si absent)
    // Note : getAllPortfolios recharge tout, y compris les tx et meta
    final portfolios = repository.getAllPortfolios();
    for (final portfolio in portfolios) {
      bool portfolioNeedsSave = false;
      for (final inst in portfolio.institutions) {
        bool institutionNeedsUpdate = false;
        final updatedAccounts = <Account>[];

        for (final acc in inst.accounts) {
          // Le constructeur Account a déjà 'EUR' par défaut, mais
          // si le champ @HiveField(5) était absent, Hive retournera null
          // lors de la désérialisation. On vérifie aussi isEmpty par sécurité.
          if (acc.currency?.isEmpty ?? true) {
            debugPrint(
                "Migration V2: Mise à jour devise pour le compte ${acc.name}");
            // Crée une NOUVELLE instance de compte avec la devise
            final updatedAccount = Account(
              id: acc.id,
              name: acc.name,
              type: acc.type,
              currency: 'EUR', // Définir la devise
              transactions: acc.transactions,
              stale_assets: acc.stale_assets,
              stale_cashBalance: acc.stale_cashBalance,
            );
            updatedAccounts.add(updatedAccount);
            institutionNeedsUpdate = true;
          } else {
            updatedAccounts.add(acc);
          }
        }

        // Si au moins un compte a été modifié, créer une nouvelle Institution
        if (institutionNeedsUpdate) {
          final updatedInstitution = Institution(
            id: inst.id,
            name: inst.name,
            accounts: updatedAccounts,
          );

          // Remplacer l'institution dans le portfolio
          final instIndex =
              portfolio.institutions.indexWhere((i) => i.id == inst.id);
          if (instIndex != -1) {
            portfolio.institutions[instIndex] = updatedInstitution;
            portfolioNeedsSave = true;
          }
        }
      }
      if (portfolioNeedsSave) {
        debugPrint(
            "Migration V2: Sauvegarde du portefeuille ${portfolio.name}");
        await repository.savePortfolio(portfolio);
      }
    }

    // 2. Mettre à jour les AssetMetadata
    final allMetadata = repository.getAllAssetMetadata().values.toList();
    for (final meta in allMetadata) {
      if (meta.priceCurrency?.isEmpty ?? true) {
        debugPrint(
            "Migration V2: Mise à jour devise pour metadata ${meta.ticker}");
        meta.priceCurrency = 'EUR';
        await repository.saveAssetMetadata(meta);
      }
    }

    // 3. Mettre à jour les Transactions
    final allTransactions = repository.getAllTransactions();
    for (final tx in allTransactions) {
      if (tx.priceCurrency == null) {
        debugPrint(
            "Migration V2: Mise à jour devise pour transaction ${tx.id}");
        // Transaction est immuable, il faut recréer
        final updatedTx = Transaction(
          id: tx.id,
          accountId: tx.accountId,
          type: tx.type,
          date: tx.date,
          amount: tx.amount,
          fees: tx.fees,
          assetTicker: tx.assetTicker,
          assetName: tx.assetName,
          quantity: tx.quantity,
          price: tx.price,
          notes: tx.notes,
          assetType: tx.assetType,
          // Assignation des nouvelles valeurs
          priceCurrency: 'EUR',
          exchangeRate: 1.0,
        );
        await repository.saveTransaction(updatedTx);
      }
    }

    await settingsProvider.setMigrationV2Done();
    debugPrint("--- FIN MIGRATION V2 ---");
  }
}
