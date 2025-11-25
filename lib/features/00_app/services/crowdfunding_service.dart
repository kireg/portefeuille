import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/repayment_type.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';

class CrowdfundingSimulationState {
  final DateTime date;
  final double liquidity;
  final double investedCapital;
  final double cumulativeInterests;
  final bool isProjected;

  CrowdfundingSimulationState({
    required this.date,
    required this.liquidity,
    required this.investedCapital,
    required this.cumulativeInterests,
    required this.isProjected,
  });
}

class CrowdfundingEvent {
  final DateTime date;
  final TransactionType type;
  final double amount;
  final String? assetId;
  final bool isProjected;

  CrowdfundingEvent({
    required this.date,
    required this.type,
    required this.amount,
    this.assetId,
    required this.isProjected,
  });
}

class CrowdfundingProjection {
  final String assetId;
  final String assetName;
  final DateTime date;
  final double amount;
  final TransactionType type; // InterestPayment or CapitalRepayment
  final bool isProjected;

  CrowdfundingProjection({
    required this.assetId,
    required this.assetName,
    required this.date,
    required this.amount,
    required this.type,
    this.isProjected = true,
  });
}

class CrowdfundingService {
  /// Generates future events (Interest, CapitalRepayment) based on current active projects
  /// and their remaining capital, derived from transaction history.
  List<CrowdfundingEvent> generateFutureEvents({
    required List<Asset> assets,
    required List<Transaction> transactions,
    int projectionMonths = 60,
  }) {
    final now = DateTime.now();
    final futureEvents = <CrowdfundingEvent>[];
    final projectionEndDate = now.add(Duration(days: (projectionMonths * 30.44).round()));
    
    // 1. Calculate Active Capital per Project based on History
    final Map<String, double> activeProjects = {}; // AssetID -> Invested Amount
    
    final relevantTransactions = transactions.where((t) {
      if (t.assetType == AssetType.RealEstateCrowdfunding) return true;
      if (t.assetTicker != null) {
        final asset = assets.where((a) => a.ticker == t.assetTicker || a.id == t.assetTicker).firstOrNull;
        if (asset != null && asset.type == AssetType.RealEstateCrowdfunding) return true;
      }
      return false;
    }).toList();

    for (final tx in relevantTransactions) {
      final amount = tx.amount;
      final assetId = tx.assetTicker;
      
      if (assetId != null) {
        if (tx.type == TransactionType.Buy) {
          // Buy amount is positive (investment cost)
          activeProjects[assetId] = (activeProjects[assetId] ?? 0) + amount;
        } else if (tx.type == TransactionType.CapitalRepayment) {
          activeProjects[assetId] = (activeProjects[assetId] ?? 0) - amount;
          if (activeProjects[assetId]! < 0.01) activeProjects[assetId] = 0;
        }
      }
    }

    // 2. Generate Future Events
    for (final entry in activeProjects.entries) {
      final assetId = entry.key;
      final remainingCapital = entry.value;
      
      if (remainingCapital <= 0.01) continue;
      
      final asset = assets.where((a) => a.ticker == assetId || a.id == assetId).firstOrNull;
      if (asset == null) continue;
      
      // Determine start date (first buy)
      final buyTransactions = transactions
          .where((t) => (t.assetTicker == assetId || t.assetTicker == asset.ticker) && t.type == TransactionType.Buy)
          .toList();
          
      if (buyTransactions.isEmpty) continue;
      buyTransactions.sort((a, b) => a.date.compareTo(b.date));
      final startDate = buyTransactions.first.date;
      
      final durationMonths = asset.targetDuration ?? 0;
      if (durationMonths <= 0) continue;
      
      final endDate = startDate.add(Duration(days: durationMonths * 30));
      final yieldRate = (asset.expectedYield ?? 0.0) / 100.0;

      if (asset.repaymentType == RepaymentType.MonthlyInterest) {
         final monthlyInterest = (remainingCapital * yieldRate) / 12;
         
         var currentDate = now; // Start projecting from now
         
         while (currentDate.isBefore(endDate) && currentDate.isBefore(projectionEndDate)) {
           currentDate = currentDate.add(const Duration(days: 30)); // Approx month
           if (currentDate.isAfter(endDate)) break;
           
           futureEvents.add(CrowdfundingEvent(
             date: currentDate,
             type: TransactionType.Interest,
             amount: monthlyInterest,
             assetId: assetId,
             isProjected: true,
           ));
         }
         
         if (endDate.isAfter(now) && endDate.isBefore(projectionEndDate)) {
           futureEvents.add(CrowdfundingEvent(
             date: endDate,
             type: TransactionType.CapitalRepayment,
             amount: remainingCapital,
             assetId: assetId,
             isProjected: true,
           ));
         }
      } else if (asset.repaymentType == RepaymentType.InFine) {
         if (endDate.isAfter(now) && endDate.isBefore(projectionEndDate)) {
           final totalInterest = remainingCapital * yieldRate * (durationMonths / 12.0);
           
           futureEvents.add(CrowdfundingEvent(
             date: endDate,
             type: TransactionType.Interest,
             amount: totalInterest,
             assetId: assetId,
             isProjected: true,
           ));
           
           futureEvents.add(CrowdfundingEvent(
             date: endDate,
             type: TransactionType.CapitalRepayment,
             amount: remainingCapital,
             assetId: assetId,
             isProjected: true,
           ));
         }
      }
    }
    
    futureEvents.sort((a, b) => a.date.compareTo(b.date));
    return futureEvents;
  }

  /// Simulates the evolution of the crowdfunding portfolio from the first transaction
  /// up to [projectionYears] into the future.
  List<CrowdfundingSimulationState> simulateCrowdfundingEvolution({
    required List<Asset> assets,
    required List<Transaction> transactions,
    List<Account> accounts = const [],
    int projectionMonths = 60,
  }) {
    final List<CrowdfundingSimulationState> history = [];
    
    // 1. Filter and Sort Transactions
    // We only care about Crowdfunding transactions
    final relevantTransactions = transactions.where((t) {
      // Explicit Crowdfunding Asset Type
      if (t.assetType == AssetType.RealEstateCrowdfunding) return true;
      
      // Or linked to a Crowdfunding Asset (by ticker/ID)
      if (t.assetTicker != null) {
        // Note: In a real app, we might need a more robust way to link transactions to assets
        // Here we assume assetTicker matches Asset.ticker or Asset.id
        final asset = assets.where((a) => a.ticker == t.assetTicker || a.id == t.assetTicker).firstOrNull;
        if (asset != null && asset.type == AssetType.RealEstateCrowdfunding) return true;
      }

      // Or linked to a Crowdfunding Account
      final account = accounts.where((a) => a.id == t.accountId).firstOrNull;
      if (account != null && account.type == AccountType.crowdfunding) return true;

      // Or specific Auto-Deposit from Import
      if ((t.type == TransactionType.Deposit || t.type == TransactionType.Withdrawal) && 
          (t.notes.contains("Apport auto") || t.notes.contains("Crowdfunding"))) {
        return true;
      }
      
      return false;
    }).toList();

    relevantTransactions.sort((a, b) => a.date.compareTo(b.date));

    // 2. Initialize State
    double liquidity = 0;
    double investedCapital = 0;
    double cumulativeInterests = 0;
    final Map<String, double> activeProjects = {}; // AssetID -> Invested Amount

    // 3. Process History
    for (final tx in relevantTransactions) {
      final amount = tx.amount;
      
      switch (tx.type) {
        case TransactionType.Deposit:
          liquidity += amount;
          break;

        case TransactionType.Withdrawal:
          // Withdrawal amount is usually negative in the system? 
          // Or positive and we subtract?
          // Let's check convention. Usually Deposit is positive, Withdrawal is negative.
          // If Withdrawal is stored as negative number: liquidity += amount (adds negative)
          // If Withdrawal is stored as positive number: liquidity -= amount
          // In this app, Buy is negative. Deposit is positive.
          // Let's assume Withdrawal is negative.
          liquidity += amount;
          break;
          
        case TransactionType.Buy:
          // Buy amount is usually positive in input, representing the cost.
          // Liquidity decreases: subtract amount
          liquidity -= amount;
          // Invested Capital increases: add amount
          investedCapital += amount;
          
          final assetId = tx.assetTicker;
          if (assetId != null) {
            activeProjects[assetId] = (activeProjects[assetId] ?? 0) + amount;
          }
          break;

        case TransactionType.Interest:
          liquidity += amount;
          cumulativeInterests += amount;
          break;
          
        case TransactionType.CapitalRepayment:
          liquidity += amount;
          investedCapital -= amount;
          
          final assetId = tx.assetTicker;
          if (assetId != null) {
            activeProjects[assetId] = (activeProjects[assetId] ?? 0) - amount;
            // Ensure we don't go below zero due to floating point errors
            if (activeProjects[assetId]! < 0.01) activeProjects[assetId] = 0;
          }
          break;
          
        // Other types will be handled later
        default:
          break;
      }

      history.add(CrowdfundingSimulationState(
        date: tx.date,
        liquidity: liquidity,
        investedCapital: investedCapital,
        cumulativeInterests: cumulativeInterests,
        isProjected: false,
      ));
    }

    // 4. Future Projections
    if (projectionMonths > 0) {
      final now = DateTime.now();
      
      // Use the shared logic to generate future events
      // Note: We pass the full lists, but generateFutureEvents will re-calculate activeProjects.
      // Optimization: We could pass activeProjects to generateFutureEvents if we refactored it to accept it.
      // For now, to avoid breaking changes and keep it simple, we just call it.
      // However, generateFutureEvents recalculates activeProjects from scratch.
      // This ensures consistency.
      
      final futureEvents = generateFutureEvents(
        assets: assets, 
        transactions: transactions, 
        projectionMonths: projectionMonths
      );
      
      for (final event in futureEvents) {
        if (event.date.isAfter(now.add(Duration(days: (projectionMonths * 30.44).round())))) break;
        
        final amount = event.amount;
        
        if (event.type == TransactionType.Interest) {
          liquidity += amount;
          cumulativeInterests += amount;
        } else if (event.type == TransactionType.CapitalRepayment) {
          liquidity += amount;
          investedCapital -= amount;
        }
        
        history.add(CrowdfundingSimulationState(
          date: event.date,
          liquidity: liquidity,
          investedCapital: investedCapital,
          cumulativeInterests: cumulativeInterests,
          isProjected: true,
        ));
      }
    }

    return history;
  }

  /// Génère les flux futurs pour une liste d'actifs de Crowdfunding
  List<CrowdfundingProjection> generateProjections(List<Asset> assets) {
    final List<CrowdfundingProjection> projections = [];
    final now = DateTime.now();

    for (final asset in assets) {
      if (asset.type != AssetType.RealEstateCrowdfunding) continue;
      if (asset.quantity <= 0) continue; // Actif vendu ou remboursé

      // On se base sur la première transaction d'achat pour déterminer le début
      // Idéalement, on devrait avoir une date de début explicite, mais la date d'achat fait l'affaire.
      final buyTransactions = asset.transactions
          .where((t) => t.type == TransactionType.Buy)
          .toList();
      
      if (buyTransactions.isEmpty) continue;
      
      // On prend la date la plus ancienne comme début du projet
      buyTransactions.sort((a, b) => a.date.compareTo(b.date));
      final startDate = buyTransactions.first.date;

      final durationMonths = asset.targetDuration ?? 0;
      if (durationMonths <= 0) continue;

      final endDate = startDate.add(Duration(days: durationMonths * 30)); // Approx
      
      // Si le projet est censé être fini et qu'on a toujours des parts, 
      // c'est qu'il est en retard. On projette un remboursement "bientôt" (ex: +1 mois)
      // ou on arrête les projections si on considère qu'on ne sait pas.
      // Ici, on va projeter jusqu'à la fin théorique si elle est dans le futur.
      
      if (endDate.isBefore(now)) {
        // Projet en retard : on pourrait ajouter une projection "Retard" ou "Remboursement estimé"
        // Pour l'instant, on ne projette rien de plus si la date cible est passée,
        // sauf si on implémente la logique "Max Duration".
        continue; 
      }

      final investedCapital = asset.quantity; // En supposant prix unitaire = 1
      final yieldRate = (asset.expectedYield ?? 0.0) / 100.0;

      if (asset.repaymentType == RepaymentType.MonthlyInterest) {
        // Intérêts mensuels
        final monthlyInterest = (investedCapital * yieldRate) / 12;
        
        var currentDate = startDate;
        // On avance mois par mois jusqu'à la fin
        while (currentDate.isBefore(endDate)) {
          currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
          
          if (currentDate.isAfter(endDate)) break;

          if (currentDate.isAfter(now)) {
             projections.add(CrowdfundingProjection(
               assetId: asset.id,
               assetName: asset.name,
               date: currentDate,
               amount: monthlyInterest,
               type: TransactionType.Interest, // Utilisation de Interest standard
             ));
          }
        }
        
        // Remboursement du capital à la fin
        if (endDate.isAfter(now)) {
           projections.add(CrowdfundingProjection(
             assetId: asset.id,
             assetName: asset.name,
             date: endDate,
             amount: investedCapital,
             type: TransactionType.CapitalRepayment,
           ));
        }

      } else if (asset.repaymentType == RepaymentType.InFine) {
        // Tout à la fin
        if (endDate.isAfter(now)) {
          // Calcul des intérêts totaux (simple pour l'instant : Capital * Taux * (Durée/12))
          final totalInterest = investedCapital * yieldRate * (durationMonths / 12.0);
          
          projections.add(CrowdfundingProjection(
             assetId: asset.id,
             assetName: asset.name,
             date: endDate,
             amount: totalInterest,
             type: TransactionType.Interest,
           ));

           projections.add(CrowdfundingProjection(
             assetId: asset.id,
             assetName: asset.name,
             date: endDate,
             amount: investedCapital,
             type: TransactionType.CapitalRepayment,
           ));
        }
      }
    }

    projections.sort((a, b) => a.date.compareTo(b.date));
    return projections;
  }
}
