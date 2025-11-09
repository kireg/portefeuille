// lib/core/ui/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // MODIFIÉ : La méthode getTheme utilise maintenant la couleur primaire
  // pour teinter les fonds (surface et scaffold).
  static ThemeData getTheme(Color primaryColor) {
    // MODIFIÉ : Réglages d'assombrissement (valeurs plus basses = plus clair)

    // Crée une couleur de surface (pour les cartes, appbar, etc.)
    // 75% noir (au lieu de 85%)
    final Color surfaceColor = Color.lerp(
      primaryColor,
      Colors.black,
      0.75, // Moins sombre
    )!;

    // Crée une couleur de fond (scaffold)
    // 85% noir (au lieu de 92%)
    final Color scaffoldColor = Color.lerp(
      primaryColor,
      Colors.black,
      0.85, // Moins sombre
    )!;

    // Crée une couleur de fond pour les inputs (légèrement plus sombre que le fond)
    final Color inputFillColor = Color.lerp(
      primaryColor,
      Colors.black,
      0.90, // Un peu plus sombre pour le contraste
    )!;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldColor, // MODIFIÉ

      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: const Color(0xFFab47bc),
        surface: surfaceColor, // MODIFIÉ
        onSurface: const Color(0xFFe0e0e0),
        error: Colors.redAccent,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor, // MODIFIÉ
        elevation: 0,
        titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFe0e0e0)),
      ),

      cardTheme: CardThemeData(
        color: surfaceColor, // MODIFIÉ
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor, // MODIFIÉ
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withAlpha(128);
          }
          return Colors.grey.withAlpha(128);
        }),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor.withAlpha(204), // MODIFIÉ
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(color: Colors.grey[400]),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}