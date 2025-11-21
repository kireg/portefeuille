import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

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
    // On utilise Align pour positionner la barre en bas au centre
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        // Marges pour l'effet "flottant"
        margin: const EdgeInsets.fromLTRB(
            AppDimens.paddingL,
            0,
            AppDimens.paddingL,
            AppDimens.paddingL // Marge du bas
        ),
        height: 64, // Hauteur compacte
        decoration: BoxDecoration(
          // Fond semi-transparent
          color: AppColors.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(32), // Forme de pilule
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        // ClipRRect + BackdropFilter pour l'effet de flou (Glassmorphism)
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

                return _buildNavItem(context, item, isSelected, () {
                  HapticFeedback.selectionClick(); // Retour haptique
                  onTap(index);
                });
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, AppNavItem item, bool isSelected, VoidCallback onTap) {
    // Animation de changement de couleur
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60, // Zone de touche large
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Classe de configuration simple pour les items
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