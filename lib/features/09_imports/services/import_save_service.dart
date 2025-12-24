import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';

class ImportSaveService {
  static Future<int> saveSelected({
    required TransactionProvider provider,
    required PortfolioProvider portfolioProvider,
    required List<ImportCandidate> candidates,
    required String accountId,
    required ImportMode mode,
    required String? sourceId,
    Map<String, AssetMetadata>? metadataByTicker,
  }) async {
    final selectedCandidates = candidates.where((c) => c.selected).toList();
    if (selectedCandidates.isEmpty) return 0;

    final modeLabel = mode == ImportMode.update ? 'Actualisation' : 'Import initial';

    final newCandidates = selectedCandidates.where((c) => c.existingMatch == null).toList();
    final modifiedCandidates = selectedCandidates.where((c) => c.existingMatch != null).toList();

    if (newCandidates.isNotEmpty) {
      final transactions = newCandidates
          .map((candidate) => Transaction(
                id: candidate.parsed.assetName + candidate.parsed.date.toIso8601String(), // id temporaire côté test, le provider réel remplacera
                accountId: accountId,
                type: candidate.parsed.type,
                date: candidate.parsed.date,
                assetTicker: candidate.parsed.ticker ?? candidate.parsed.isin,
                assetName: candidate.parsed.assetName,
                quantity: candidate.parsed.quantity,
                price: candidate.parsed.price,
                amount: candidate.parsed.amount,
                fees: candidate.parsed.fees,
                notes: "$modeLabel depuis $sourceId",
                assetType: candidate.parsed.assetType,
                priceCurrency: candidate.parsed.currency,
              ))
          .toList();
      await provider.addTransactions(transactions);
    }

    for (final candidate in modifiedCandidates) {
      final existing = candidate.existingMatch!;
      final updated = Transaction(
        id: existing.id,
        accountId: existing.accountId,
        type: existing.type,
        date: existing.date,
        assetTicker: existing.assetTicker,
        assetName: existing.assetName,
        quantity: candidate.parsed.quantity,
        price: candidate.parsed.price,
        amount: candidate.parsed.amount,
        fees: candidate.parsed.fees ?? existing.fees,
        notes: "Mise à jour ($modeLabel) depuis $sourceId",
        assetType: existing.assetType,
        priceCurrency: candidate.parsed.currency ?? existing.priceCurrency,
      );
      await provider.updateTransaction(updated);
    }

    return selectedCandidates.length;
  }
}
