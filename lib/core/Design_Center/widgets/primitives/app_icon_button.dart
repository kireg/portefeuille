import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_animations.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';

class AppIconButton extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final String? tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  const AppIconButton({
    super.key,
    required this.icon,
    this.color,
    this.tooltip,
    required this.onPressed,
    this.size = 24.0,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 8.0,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: isDisabled ? null : (_) => setState(() => _isHovered = true),
      onExit: isDisabled ? null : (_) => setState(() => _isHovered = false),
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.1 : 1.0,
        duration: AppAnimations.normal,
        curve: AppAnimations.curveEaseOutBack,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: widget.borderColor != null ? Border.all(color: widget.borderColor!) : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: IconButton(
            icon: Icon(widget.icon, size: widget.size),
            color: widget.color,
            tooltip: widget.tooltip,
            onPressed: widget.onPressed,
            padding: AppSpacing.iconButtonPadding,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
