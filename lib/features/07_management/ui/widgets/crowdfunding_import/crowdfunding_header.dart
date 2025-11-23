import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/feedback/premium_help_button.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';

class CrowdfundingHeader extends StatelessWidget {
  const CrowdfundingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.paddingL,
          AppDimens.paddingL,
          AppDimens.paddingM,
          AppDimens.paddingM
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              'Import Crowdfunding',
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: const PremiumHelpButton(
              title: "Guide d'import",
              content: "Pour importer vos investissements :\n\n1. Connectez-vous à votre espace client La Première Brique.\n2. Allez dans la section 'Mes Investissements'.\n3. Cliquez sur le bouton 'Exporter' (format Excel).\n4. Sélectionnez le fichier téléchargé ici.\n\nCe fichier contient tous les détails nécessaires (Montant, Durée, Taux, etc.) pour un suivi précis.",
              visual: Icon(Icons.table_view_rounded, size: 48, color: AppColors.primary),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AppIcon(
              icon: Icons.close,
              onTap: () => Navigator.of(context).pop(),
              backgroundColor: Colors.transparent,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
