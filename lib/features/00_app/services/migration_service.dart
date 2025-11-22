// lib/features/00_app/services/migration_service.dart

// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:uuid/uuid.dart';

class MigrationService {
  final PortfolioRepository _repository;
  final Uuid _uuid;

  MigrationService({
    required PortfolioRepository repository,
    Uuid? uuid,
  })  : _repository = repository,
        _uuid = uuid ?? const Uuid();

  /// Convertit les champs `stale_` en transactions (Migration V1).
  Future<bool> runMigrationV1(List<Portfolio> portfolios) async {
    final needsMigration = portfolios.any((p) => p.institutions.any((i) =>
        i.accounts.any((a) =>
        a.staleCashBalance != null ||
            (a.staleAssets?.isNotEmpty ?? false))));

    if (!needsMigration) {
      debugPrint("Migration V1 : Aucune donnée périmée trouvée.");
      return false;
    }

    debugPrint("--- DÉBUT MIGRATION V1 ---");
    final newTransactions = <Transaction>[];

    for (final portfolio in portfolios) {
      bool portfolioNeedsSave = false;

      for (final inst in portfolio.institutions) {
        for (final acc in inst.accounts) {
          final migrationDate = DateTime(2020, 1, 1);
          double totalCashFromAssets = 0.0;

          if (acc.staleAssets != null && acc.staleAssets!.isNotEmpty) {
            for (final asset in acc.staleAssets!) {
              final qty = asset.staleQuantity;
              final pru = asset.staleAveragePrice;
              if (qty != null && pru != null && qty > 0) {
                totalCashFromAssets += (qty * pru);
              }
            }
          }

          final totalCashNeeded =
              (acc.staleCashBalance ?? 0.0) + totalCashFromAssets;

          if (totalCashNeeded > 0) {
            debugPrint(
                "Migration : Ajout Dépôt initial de ${totalCashNeeded.toStringAsFixed(2)}€ pour ${acc.name}");
            newTransactions.add(Transaction(
              id: _uuid.v4(),
              accountId: acc.id,
              type: TransactionType.Deposit,
              date: migrationDate,
              amount: totalCashNeeded,
              notes:
              "Migration v1 - Dépôt initial (Solde: ${acc.staleCashBalance?.toStringAsFixed(2) ?? '0.00'}€)",
            ));
            acc.staleCashBalance = null;
            portfolioNeedsSave = true;
          }

          if (acc.staleAssets != null && acc.staleAssets!.isNotEmpty) {
            debugPrint(
                "Migration : ${acc.staleAssets!.length} actifs pour ${acc.name}");
            for (final asset in acc.staleAssets!) {
              final qty = asset.staleQuantity;
              final pru = asset.staleAveragePrice;

              if (qty != null && pru != null && qty > 0) {
                final totalCost = qty * pru;
                debugPrint(
                    "Migration : Actif ${asset.ticker} (Qty: $qty, PRU: ${pru.toStringAsFixed(2)}€)");
                newTransactions.add(Transaction(
                  id: _uuid.v4(),
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
            acc.staleAssets = null;
            portfolioNeedsSave = true;
          }
        }
      }

      if (portfolioNeedsSave) {
        debugPrint("Migration : Nettoyage du portefeuille ${portfolio.name}");
        await _repository.savePortfolio(portfolio);
      }
    }

    debugPrint(
        "Migration : Sauvegarde de ${newTransactions.length} transactions...");
    await Future.wait(
      newTransactions.map(_repository.saveTransaction),
    );

    debugPrint("--- FIN MIGRATION V1 ---");
    return true;
  }

  /// Met à jour les données V1 (sans devise) vers V2 (avec devise).
  /// Suppose que toutes les données existantes sont en EUR.
  Future<bool> runMigrationV2() async {
    debugPrint("--- DÉBUT MIGRATION V2 (Devises) ---");
    bool hasChanges = false;

    // 1. Mettre à jour les Comptes
    final portfolios = _repository.getAllPortfolios();
    for (final portfolio in portfolios) {
      bool portfolioNeedsSave = false;

      for (final inst in portfolio.institutions) {
        bool institutionNeedsUpdate = false;
        final updatedAccounts = <Account>[];

        for (final acc in inst.accounts) {
          if (acc.currency?.isEmpty ?? true) {
            debugPrint(
                "Migration V2: Mise à jour devise pour le compte ${acc.name}");
            final updatedAccount = Account(
              id: acc.id,
              name: acc.name,
              type: acc.type,
              currency: 'EUR',
              transactions: acc.transactions,
              staleAssets: acc.staleAssets,
              staleCashBalance: acc.staleCashBalance,
            );
            updatedAccounts.add(updatedAccount);
            institutionNeedsUpdate = true;
            hasChanges = true;
          } else {
            updatedAccounts.add(acc);
          }
        }

        if (institutionNeedsUpdate) {
          final updatedInstitution = Institution(
            id: inst.id,
            name: inst.name,
            accounts: updatedAccounts,
          );

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
        await _repository.savePortfolio(portfolio);
      }
    }

    // 2. Mettre à jour les AssetMetadata
    final allMetadata = _repository.getAllAssetMetadata().values.toList();
    await Future.wait(
      allMetadata.where((meta) => meta.priceCurrency?.isEmpty ?? true).map(
            (meta) async {
          debugPrint(
              "Migration V2: Mise à jour devise pour metadata ${meta.ticker}");
          meta.priceCurrency = 'EUR';
          await _repository.saveAssetMetadata(meta);
          hasChanges = true;
        },
      ),
    );

    // 3. Mettre à jour les Transactions
    final allTransactions = _repository.getAllTransactions();
    await Future.wait(
      allTransactions.where((tx) => tx.priceCurrency == null).map(
            (tx) async {
          debugPrint(
              "Migration V2: Mise à jour devise pour transaction ${tx.id}");
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
            priceCurrency: 'EUR',
            exchangeRate: 1.0,
          );
          await _repository.saveTransaction(updatedTx);
          hasChanges = true;
        },
      ),
    );

    debugPrint("--- FIN MIGRATION V2 ---");
    return hasChanges;
  }
}