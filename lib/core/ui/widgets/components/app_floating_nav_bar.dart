import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart'; // Nécessaire pour le style du Tooltip

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
        margin: const EdgeInsets.fromLTRB(
            AppDimens.paddingL,
            0,
            AppDimens.paddingL,
            AppDimens.paddingL
        ),
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: AppTypography.caption.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      waitDuration: const Duration(milliseconds: 500), // Léger délai avant affichage

      // Zone interactive
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          // Effet circulaire comme sur l'AppBar
          customBorder: const CircleBorder(),
          // Couleur de survol (hover) subtile
          hoverColor: AppColors.primary.withValues(alpha: 0.1),
          splashColor: AppColors.primary.withValues(alpha: 0.2),

          child: Container(
            width: 60, // Zone de touche large
            height: double.infinity,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10), // Padding interne de l'icône
              decoration: BoxDecoration(
                // Si sélectionné : fond subtil. Sinon transparent.
                color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
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