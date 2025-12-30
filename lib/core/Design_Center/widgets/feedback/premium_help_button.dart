import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_elevations.dart';
import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';

class PremiumHelpButton extends StatelessWidget {
  final String title;
  final String content;
  final Widget? visual;
  final Color? iconColor;

  const PremiumHelpButton({
    super.key,
    required this.title,
    required this.content,
    this.visual,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.info_outline_rounded,
        color: (iconColor ?? AppColors.textSecondary).withValues(alpha: AppOpacities.prominent),
        size: AppComponentSizes.iconMediumSmall,
      ),
      splashRadius: 20,
      tooltip: 'Information',
      onPressed: () => _showPremiumHelpSheet(context),
    );
  }

  void _showPremiumHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PremiumHelpSheet(
        title: title,
        content: content,
        visual: visual,
      ),
    );
  }
}

class _PremiumHelpSheet extends StatelessWidget {
  final String title;
  final String content;
  final Widget? visual;

  const _PremiumHelpSheet({
    required this.title,
    required this.content,
    this.visual,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: AppOpacities.almostOpaque),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: AppColors.textPrimary.withValues(alpha: AppOpacities.lightOverlay),
              width: 1,
            ),
          ),
          boxShadow: AppElevations.md,
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar for visual affordance
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: AppOpacities.decorative),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                ),
              ),
            ),
            AppSpacing.gapL,
            
            // Title
            Text(
              title,
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.gapM,
            
            // Visual (Optional)
            if (visual != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: AppOpacities.semiVisible),
                  borderRadius: BorderRadius.circular(AppDimens.radius12),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: AppOpacities.lightOverlay),
                  ),
                ),
                child: visual,
              ),
              AppSpacing.gapM,
            ],
            
            // Content
            Text(
              content,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            
            AppSpacing.gapL,
            
            // Close Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radius12),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: AppOpacities.lightOverlay),
                ),
                child: Text(
                  'Compris',
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
