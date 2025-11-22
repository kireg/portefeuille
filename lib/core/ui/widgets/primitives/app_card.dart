import 'dart:ui'; // Nécessaire pour ImageFilter
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool withShadow;
  final bool isGlass; // Nouvelle option pour forcer/désactiver le verre

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.withShadow = true,
    this.isGlass = true, // Activé par défaut pour le look Premium
  });

  @override
  Widget build(BuildContext context) {
    // 1. La décoration (Bordure + Ombre + Couleur de fond)
    final decoration = BoxDecoration(
      // Si une couleur est forcée, on l'utilise. Sinon gradient par défaut.
      color: backgroundColor,
      gradient: backgroundColor == null ? AppColors.surfaceGradient : null,

      borderRadius: BorderRadius.circular(AppDimens.radiusM),

      // Bordure subtile "Verre" (blanche très transparente)
      border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1
      ),

      // Ombre portée
      boxShadow: withShadow
          ? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4, // Ombre plus diffuse
        ),
      ]
          : null,
    );

    Widget content = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppDimens.paddingM),
      child: child,
    );

    // 2. Application de l'effet de flou (Glassmorphism)
    if (isGlass && backgroundColor == null) {
      // ClipRRect est nécessaire pour que le flou ne dépasse pas les bords arrondis
      content = ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Flou puissant
          child: Container(
            decoration: decoration, // La décoration est appliquée SUR le flou
            child: content,
          ),
        ),
      );
    } else {
      // Version standard (sans flou, pour les perfs ou si couleur unie)
      content = Container(
        decoration: decoration,
        child: content,
      );
    }

    // 3. Gestion du clic (Ripple effect)
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          child: content,
        ),
      );
    }

    return content;
  }
}