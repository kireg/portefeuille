import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';

import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';

class EmptyTransactionsWidget extends StatelessWidget {
  final VoidCallback? onAdd;

  const EmptyTransactionsWidget({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: AppCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon(
              icon: Icons.receipt_long_outlined,
              size: 48,
              backgroundColor: AppColors.surfaceLight,
            ),
            const SizedBox(height: AppDimens.paddingM),
            Text('Aucune transaction', style: AppTypography.h3),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Pour commencer, assurez-vous d\'avoir créé un compte dans l\'onglet "Vue".\n\nVous pouvez ensuite ajouter des transactions manuellement ou utiliser les boutons d\'import (PDF, Excel, IA) situés dans la barre d\'outils ci-dessus pour importer plusieurs transactions en une seule fois.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            if (onAdd != null) ...[
              const SizedBox(height: AppDimens.paddingM),
              AppButton(
                label: "Ajouter une transaction manuelle",
                icon: Icons.add,
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
