import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';

/// Footer du wizard avec boutons Précédent/Suivant.
class WizardFooter extends StatelessWidget {
  final int currentStep;
  final bool canProceed;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const WizardFooter({
    super.key,
    required this.currentStep,
    required this.canProceed,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: AppButton(
                label: 'Précédent',
                type: AppButtonType.secondary,
                onPressed: onPrevious,
              ),
            ),
          if (currentStep > 0) AppSpacing.gapHorizontalMedium,
          Expanded(
            child: AppButton(
              label: currentStep == 2 ? 'Terminer' : 'Suivant',
              type: AppButtonType.primary,
              onPressed: canProceed ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}
