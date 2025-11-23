import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';

enum AppButtonType { primary, secondary, ghost }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? textColor; // AJOUT

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.textColor, // AJOUT
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _controller.forward(),
      onTapUp: isDisabled ? null : (_) => _controller.reverse(),
      onTapCancel: isDisabled ? null : () => _controller.reverse(),
      onTap: isDisabled ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            width: widget.isFullWidth ? double.infinity : null,
            alignment: Alignment.center, // Fix: Center content to prevent loader stretching
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 24,
            ),
            decoration: _getDecoration(),
            child: widget.isLoading
                ? _buildLoader()
                : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: _getTextColor()),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: _getTextColor(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getDecoration() {
    // On récupère la couleur active du thème (celle choisie par l'user)
    final primaryColor = Theme.of(context).colorScheme.primary;

    switch (widget.type) {
      case AppButtonType.primary:
        return BoxDecoration(
          // Gradient dynamique basé sur la couleur choisie
          gradient: LinearGradient(
            colors: [
              primaryColor,
              Color.lerp(primaryColor, Colors.black, 0.2) ?? primaryColor, // Version un peu plus sombre
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4), // Ombre colorée
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case AppButtonType.secondary:
        return BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        );
      case AppButtonType.ghost:
        return const BoxDecoration();
    }
  }

  Color _getTextColor() {
    if (widget.textColor != null) return widget.textColor!; // Priorité à la couleur explicite

    switch (widget.type) {
      case AppButtonType.primary:
        return Colors.white;
      case AppButtonType.secondary:
        return AppColors.textPrimary;
      case AppButtonType.ghost:
        return AppColors.textSecondary;
    }
  }

  Widget _buildLoader() {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
      ),
    );
  }
}