import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';

/// Header du wizard avec poignée de glissement et titre.
class WizardHeader extends StatelessWidget {
  final VoidCallback onClose;

  const WizardHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
              Expanded(
                child: Text(
                  'Assistant d\'Import',
                  style: AppTypography.h3,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the close button
            ],
          ),
        ],
      ),
    );
  }
}

/// Indicateur de progression en 3 étapes.
class WizardProgressIndicator extends StatelessWidget {
  final int currentStep;

  const WizardProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          _buildStepDot(0),
          _buildStepLine(currentStep >= 1),
          _buildStepDot(1),
          _buildStepLine(currentStep >= 2),
          _buildStepDot(2),
        ],
      ),
    );
  }

  Widget _buildStepDot(int index) {
    final isActive = currentStep >= index;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: AppTypography.bodyBold.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppColors.primary : AppColors.surfaceLight,
      ),
    );
  }
}
