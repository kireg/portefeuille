import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimens.dart';

class AppTheme {
  static ThemeData getTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // On teinte aussi le fond de l'application très légèrement
      scaffoldBackgroundColor: Color.alphaBlend(
          primaryColor.withValues(alpha: 0.02), // 2% de la couleur choisie
          AppColors.background // sur le fond noir
      ),
      fontFamily: 'Manrope',

      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        error: AppColors.error,
        onSurface: AppColors.textPrimary,
      ).copyWith(
        // C'est ICI que la magie opère : on injecte la couleur utilisateur
        primary: primaryColor,
        secondary: primaryColor, // Ou une variante
        // On utilise la couleur primaire pour teinter légèrement le fond
        surfaceTint: primaryColor.withValues(alpha: AppOpacities.subtle),
      ),

      textTheme: TextTheme(
        headlineLarge: AppTypography.hero,
        headlineMedium: AppTypography.h1,
        titleLarge: AppTypography.h2,
        titleMedium: AppTypography.h3,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.label,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.h3,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.all(AppDimens.paddingM),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          // La bordure active prendra la couleur choisie
          borderSide: BorderSide(color: primaryColor),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.textPrimary),
        closeIconColor: AppColors.textPrimary,
        actionTextColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusS)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}