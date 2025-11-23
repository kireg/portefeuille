import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/feedback/premium_help_button.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';

class PdfHeader extends StatelessWidget {
  const PdfHeader({super.key});

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
              'Import PDF',
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: const PremiumHelpButton(
              title: "Guide d'import PDF",
              content: "Pour importer vos transactions depuis un relevé PDF :\n\n1. Téléchargez votre relevé de compte ou d'opérations (format PDF).\n2. Sélectionnez le fichier ici.\n3. L'application va tenter d'extraire les transactions.\n4. Vérifiez et corrigez les données si nécessaire avant de valider.",
              visual: Icon(Icons.picture_as_pdf_rounded, size: 48, color: AppColors.primary),
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
