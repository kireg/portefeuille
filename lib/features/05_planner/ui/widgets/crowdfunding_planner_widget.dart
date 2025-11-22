import 'package:flutter/gestures.dart'; // Pour ScrollConfiguration
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/00_app/services/crowdfunding_service.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';

class CrowdfundingPlannerWidget extends StatelessWidget {
  final List<Asset> assets;
  final List<Transaction> transactions;

  const CrowdfundingPlannerWidget({
    super.key,
    required this.assets,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    // Utilisation du service (idéalement injecté ou via un provider dédié)
    final service = CrowdfundingService();
    
    // Utilisation de la nouvelle méthode generateFutureEvents qui est plus précise
    final futureEvents = service.generateFutureEvents(
      assets: assets,
      transactions: transactions,
      projectionMonths: 24, // On regarde les 2 prochaines années pour le planner
    );

    if (futureEvents.isEmpty) {
      return const SizedBox.shrink(); // Rien à afficher si pas de crowdfunding
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
          child: Text(
            "Prochains Paiements",
            style: AppTypography.h3,
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        
        SizedBox(
          height: 160,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
              itemCount: futureEvents.length,
              itemBuilder: (context, index) {
                final event = futureEvents[index];
                final isCapital = event.type == TransactionType.CapitalRepayment;
                
                // Récupérer le nom de l'actif
                final asset = assets.where((a) => a.id == event.assetId || a.ticker == event.assetId).firstOrNull;
                final assetName = asset?.name ?? event.assetId ?? "Inconnu";

                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: AppDimens.paddingS),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    backgroundColor: isCapital ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy', 'fr_FR').format(event.date),
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${event.amount.toStringAsFixed(2)} €",
                          style: AppTypography.h3.copyWith(
                            color: isCapital ? AppColors.primary : AppColors.success,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assetName,
                          style: AppTypography.body.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isCapital ? "Remboursement" : "Intérêts",
                          style: AppTypography.caption.copyWith(
                            color: isCapital ? AppColors.primary : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
