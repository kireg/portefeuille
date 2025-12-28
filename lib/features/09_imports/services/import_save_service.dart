import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';

class ImportSaveService {
  /// Sauvegarde les transactions sélectionnées.
  /// 
  /// Pour les imports crowdfunding, crée automatiquement un dépôt compensatoire
  /// par date unique d'investissement pour neutraliser l'impact sur les liquidités.
  /// Cela reflète le fait que l'argent était déjà disponible avant l'import.
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
      final List<Transaction> transactions = [];
      
      // Grouper les achats crowdfunding par date pour créer un seul dépôt compensatoire par date
      final Map<String, double> crowdfundingDepositsByDate = {};
      
      for (final candidate in newCandidates) {
        final parsed = candidate.parsed;
        
        // Créer la transaction d'achat
        transactions.add(Transaction(
          id: parsed.assetName + parsed.date.toIso8601String(),
          accountId: accountId,
          type: parsed.type,
          date: parsed.date,
          assetTicker: parsed.ticker ?? parsed.isin,
          assetName: parsed.assetName,
          quantity: parsed.quantity,
          price: parsed.price,
          amount: parsed.amount,
          fees: parsed.fees,
          notes: "$modeLabel depuis $sourceId",
          assetType: parsed.assetType,
          priceCurrency: parsed.currency,
        ));
        
        // Pour les achats crowdfunding, calculer le dépôt compensatoire
        // Le montant de l'achat est négatif, donc on doit ajouter son opposé (positif)
        if (parsed.type == TransactionType.Buy && 
            parsed.assetType == AssetType.RealEstateCrowdfunding) {
          final dateKey = parsed.date.toIso8601String().substring(0, 10); // YYYY-MM-DD
          crowdfundingDepositsByDate[dateKey] = 
              (crowdfundingDepositsByDate[dateKey] ?? 0) + parsed.amount.abs();
        }
      }
      
      // Créer les dépôts compensatoires pour neutraliser l'impact sur les liquidités
      for (final entry in crowdfundingDepositsByDate.entries) {
        final dateStr = entry.key;
        final amount = entry.value;
        final date = DateTime.parse(dateStr);
        
        transactions.add(Transaction(
          id: 'deposit_auto_$dateStr',
          accountId: accountId,
          type: TransactionType.Deposit,
          date: date,
          amount: amount,
          notes: "Apport auto - Crowdfunding ($modeLabel depuis $sourceId)",
          priceCurrency: 'EUR',
        ));
      }
      
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
