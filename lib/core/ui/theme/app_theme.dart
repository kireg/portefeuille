// lib/core/ui/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // MODIFIÉ : darkTheme n'est plus un `static final`
  // C'est maintenant une méthode qui génère un thème.
  static ThemeData getTheme(Color primaryColor) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1a2943),

      colorScheme: ColorScheme.dark(
        primary: primaryColor, // MODIFIÉ
        secondary: const Color(0xFFab47bc), // Reste inchangé (ou peut aussi être dynamique)
        surface: const Color(0xFF294166),
        onSurface: const Color(0xFFe0e0e0),
        error: Colors.redAccent,
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF294166),
        elevation: 0,
        titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFe0e0e0)),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF294166),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF294166),
        selectedItemColor: primaryColor, // MODIFIÉ
        unselectedItemColor: Colors.grey,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor; // MODIFIÉ
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withAlpha(128); // MODIFIÉ
          }
          return Colors.grey.withAlpha(128);
        }),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1a2943).withAlpha(204),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(color: Colors.grey[400]),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // MODIFIÉ
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor, // MODIFIÉ
          side: BorderSide(color: primaryColor), // MODIFIÉ
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}