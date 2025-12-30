import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_component_sizes.dart';

class AppIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final VoidCallback? onTap;

  const AppIcon({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.size = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      padding: AppSpacing.iconPaddingStandard,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppComponentSizes.iconBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(
        icon,
        size: size,
        color: color ?? AppColors.textSecondary,
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: widget);
    }

    return widget;
  }
}