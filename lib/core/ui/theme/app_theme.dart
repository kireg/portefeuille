import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1a2943),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00bcd4),      // Cyan
      secondary: Color(0xFFab47bc),    // Violet
      surface: Color(0xFF294166),      // Couleur des cartes/blocs
      onSurface: Color(0xFFe0e0e0),    // Texte principal
      error: Colors.redAccent,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF294166),
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFe0e0e0)),
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF294166),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF294166),
      selectedItemColor: Color(0xFF00bcd4), // Cyan
      unselectedItemColor: Colors.grey,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF00bcd4); // Cyan
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF00bcd4).withAlpha(128);
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
        backgroundColor: const Color(0xFF00bcd4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00bcd4),
        side: const BorderSide(color: Color(0xFF00bcd4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
