import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_icon.dart';

class FormHeader extends StatelessWidget {
  const FormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();

    return SizedBox(
      height: 40,
      width: double.infinity, // Force la largeur totale pour permettre le centrage
      child: Stack(
        children: [
          // 1. TITRE (Centré absolument dans le Stack)
          Center(
            child: Padding(
              // Padding horizontal pour éviter que le texte ne touche le bouton croix sur petits écrans
              padding: AppSpacing.modalHeaderPadding,
              child: Text(
                state.isEditing ? 'Modifier' : 'Nouvelle Transaction',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 2. BOUTON FERMER (Ancré à Droite)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: AppIcon(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
                backgroundColor: Colors.transparent,
                size: AppComponentSizes.iconMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}