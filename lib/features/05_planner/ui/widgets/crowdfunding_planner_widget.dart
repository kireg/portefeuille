import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/services/crowdfunding_service.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';

class CrowdfundingPlannerWidget extends StatelessWidget {
  const CrowdfundingPlannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final assets = provider.activePortfolio?.assets ?? [];
    
    // Utilisation du service (idéalement injecté ou via un provider dédié)
    final service = CrowdfundingService();
    final projections = service.generateProjections(assets);

    if (projections.isEmpty) {
      return const SizedBox.shrink(); // Rien à afficher si pas de crowdfunding
    }

    // Groupement par mois pour l'affichage
    final grouped = <String, double>{};
    for (var p in projections) {
      final key = DateFormat('MMMM yyyy', 'fr_FR').format(p.date);
      grouped[key] = (grouped[key] ?? 0.0) + p.amount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
          child: Text(
            "Projections Crowdfunding Immo",
            style: AppTypography.h3,
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
            itemCount: projections.length, // Suppression de la limite arbitraire
            itemBuilder: (context, index) {
              final proj = projections[index];
              final isCapital = proj.type == TransactionType.CapitalRepayment;
              
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: AppDimens.paddingS),
                child: AppCard(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  backgroundColor: isCapital ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy', 'fr_FR').format(proj.date),
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${proj.amount.toStringAsFixed(2)} €",
                        style: AppTypography.h3.copyWith(
                          color: isCapital ? AppColors.primary : AppColors.success,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        proj.assetName,
                        style: AppTypography.body.copyWith(fontSize: 12), // Correction bodySmall -> body + fontSize
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
      ],
    );
  }
}
