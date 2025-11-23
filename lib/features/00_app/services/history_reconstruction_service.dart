import 'package:flutter/foundation.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/portfolio_value_history_point.dart';

class HistoryReconstructionService {
  
  /// Reconstruit l'historique de valeur du portefeuille basé sur les transactions.
  /// 
  /// Stratégie :
  /// - On parcourt les jours depuis la première transaction.
  /// - On maintient l'état du portefeuille (quantités d'actifs).
  /// - Pour le prix :
  ///   - On utilise le prix de la transaction comme "prix connu".
  ///   - Entre deux transactions, on garde le dernier prix connu (Step).
  ///   - C'est une approximation, mais c'est le mieux qu'on puisse faire sans API historique.
  ///   - Pour le Cash, le prix est toujours 1.0 (dans la devise du compte).
  List<PortfolioValueHistoryPoint> reconstructHistory(Portfolio portfolio) {
    debugPrint("--- 📜 Reconstruction de l'historique ---");
    
    // 1. Récupérer toutes les transactions à plat
    final allTransactions = portfolio.institutions
        .expand((inst) => inst.accounts)
        .expand((acc) => acc.transactions)
        .toList();

    if (allTransactions.isEmpty) {
      debugPrint("  -> Aucune transaction, historique vide.");
      return [];
    }

    // Trier par date
    allTransactions.sort((a, b) => a.date.compareTo(b.date));

    final startDate = allTransactions.first.date;
    final endDate = DateTime.now();
    
    // État courant
    final Map<String, double> quantities = {}; // Ticker -> Quantity
    final Map<String, double> lastKnownPrices = {}; // Ticker -> Price
    
    // Pour gérer les devises, c'est complexe sans taux de change historiques.
    // On va supposer que tout est converti dans la devise de base ou ignorer la conversion pour l'instant (somme brute).
    // Idéalement, il faudrait les taux historiques.
    // On va faire une somme simple des valeurs (Quantity * Price) en supposant que les prix sont dans la même devise ou que l'utilisateur gère ça.
    // Note: Dans l'app, chaque compte a une devise.
    
    final List<PortfolioValueHistoryPoint> history = [];
    
    // Index de transaction courant
    int txIndex = 0;

    // On itère jour par jour
    // Pour optimiser, on pourrait sauter aux jours de transaction, mais on veut un point par jour (ou semaine) pour le graphe.
    // On va générer un point par jour.
    
    for (var day = startDate; day.isBefore(endDate) || day.isAtSameMomentAs(endDate); day = day.add(const Duration(days: 1))) {

      // Appliquer les transactions du jour
      while (txIndex < allTransactions.length && _isSameDay(allTransactions[txIndex].date, day)) {
        final tx = allTransactions[txIndex];
        _applyTransaction(tx, quantities, lastKnownPrices);
        txIndex++;
      }

      // Si c'est le dernier jour, ou s'il y a eu des changements, ou périodiquement (ex: chaque semaine)
      // Pour un graphe fluide, on peut prendre chaque jour.
      // Si on a beaucoup de jours, ça fait beaucoup de points.
      // On va prendre chaque jour s'il y a changement, sinon on répète la valeur précédente ?
      // Non, le graphe a besoin de points réguliers ou au moins aux changements.
      
      // Calculer la valeur totale ce jour-là
      double totalValue = 0.0;
      quantities.forEach((ticker, qty) {
        final price = lastKnownPrices[ticker] ?? 0.0;
        totalValue += qty * price;
      });

      // Ajouter le point (on écrase s'il existe déjà pour ce jour, mais ici on génère une nouvelle liste)
      // On évite les doublons de date si on itère jour par jour.
      
      // Optimisation : Si la valeur n'a pas changé depuis le dernier point, on n'ajoute pas forcément de point,
      // SAUF si on veut une ligne plate explicite. Fl_chart gère bien les lignes.
      // Mais pour "l'évolution", c'est bien d'avoir un point par jour.
      
      history.add(PortfolioValueHistoryPoint(date: day, value: totalValue));
    }

    debugPrint("  -> Historique reconstruit : ${history.length} points.");
    return history;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  void _applyTransaction(Transaction tx, Map<String, double> quantities, Map<String, double> lastKnownPrices) {
    final ticker = tx.assetTicker ?? tx.assetName ?? 'UNKNOWN';
    
    // Mise à jour du prix si disponible (Buy/Sell)
    if (tx.price != null && tx.price! > 0) {
      lastKnownPrices[ticker] = tx.price!;
    }

    // Mise à jour de la quantité
    final currentQty = quantities[ticker] ?? 0.0;
    
    switch (tx.type) {
      case TransactionType.Buy:
        quantities[ticker] = currentQty + (tx.quantity ?? 0.0);
        break;
      case TransactionType.Sell:
        quantities[ticker] = currentQty - (tx.quantity ?? 0.0);
        break;
      case TransactionType.Deposit:
        break;
      case TransactionType.Withdrawal:
        break;
      default:
        break;
    }
    
    // Nettoyage des quantités nulles (optionnel)
    if ((quantities[ticker] ?? 0).abs() < 0.000001) {
      quantities.remove(ticker);
    }
  }
}
