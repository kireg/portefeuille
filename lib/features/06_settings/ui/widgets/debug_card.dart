import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_button.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/services/route_manager.dart';

class DebugCard extends StatelessWidget {
  const DebugCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: AppColors.warning),
              const SizedBox(width: AppDimens.paddingM),
              Text('Debug & Maintenance', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            "Outils avancés pour corriger des problèmes de données.",
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.paddingM),
          AppButton(
            label: "Reconstruire l'historique",
            icon: Icons.history_edu,
            type: AppButtonType.secondary,
            textColor: AppColors.textPrimary,
            onPressed: () async {
              final provider = Provider.of<PortfolioProvider>(context, listen: false);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Reconstruction en cours...")),
              );
              
              await provider.reconstructPortfolioHistory();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Historique reconstruit avec succès !")),
                );
              }
            },
          ),
          const SizedBox(height: AppDimens.paddingS),
          AppButton(
            label: "BoxSand (Extraction PDF)",
            icon: Icons.picture_as_pdf,
            type: AppButtonType.secondary,
            textColor: AppColors.textPrimary,
            onPressed: () {
              Navigator.pushNamed(context, RouteManager.boxSand);
            },
          ),
        ],
      ),
    );
  }
}
