import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_elevations.dart';
import '../../theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';

class AppFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<AppNavItem> items;

  const AppFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.fromLTRB(
            AppSpacing.navBarMarginHorizontal,
            0,
            AppSpacing.navBarMarginHorizontal,
            AppSpacing.navBarMarginBottom
        ),
        height: AppDimens.floatingNavBarHeight,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: AppOpacities.almostOpaque),
          borderRadius: BorderRadius.circular(AppDimens.radius32),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppElevations.lg,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radius32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = currentIndex == index;

                return Flexible(
                  child: _buildNavItem(context, item, isSelected, () {
                    HapticFeedback.selectionClick();
                    onTap(index);
                  }),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, AppNavItem item, bool isSelected, VoidCallback onTap) {
    // On utilise Tooltip pour afficher le nom au survol
    return Tooltip(
      message: item.label,
      // Personnalisation du Tooltip pour coller au thème de l'app
      decoration: BoxDecoration(
        color: AppColors.surface, // Fond sombre
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        border: Border.all(color: AppColors.border), // Bordure subtile
        boxShadow: AppElevations.sm,
      ),
      textStyle: AppTypography.caption.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      waitDuration: AppAnimations.delayTooltip,

      // Zone interactive
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          // Effet circulaire comme sur l'AppBar
          customBorder: const CircleBorder(),
          // Couleur de survol (hover) subtile
          hoverColor: AppColors.primary.withValues(alpha: AppOpacities.lightOverlay),
          splashColor: AppColors.primary.withValues(alpha: AppOpacities.border),

          child: Container(
            width: 60, // Zone de touche large
            height: double.infinity,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: AppAnimations.normal,
              padding: const EdgeInsets.all(10), // Padding interne de l'icône
              decoration: BoxDecoration(
                // Si sélectionné : fond subtil. Sinon transparent.
                color: isSelected ? AppColors.primary.withValues(alpha: AppOpacities.surfaceTint) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: AppComponentSizes.iconMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AppNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}