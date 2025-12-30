import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';

class AppColors {
  // --- SURFACES ---
  // Noir profond avec une légère teinte bleue pour éviter le "noir éteint"
  static const Color background = Color(0xFF05050A);

  // Utilisé pour les cartes (Légèrement plus clair que le fond)
  static const Color surface = Color(0xFF101016);

  // Utilisé pour les éléments surélevés ou les inputs
  static const Color surfaceLight = Color(0xFF1C1C26);

  // --- ACCENTS ---
  // Bleu électrique (Marque principale)
  static const Color primary = Color(0xFF4B68FF);
  static const Color primaryDark = Color(0xFF2B40CC);

  // Violet/Rose néon (Secondaire)
  static const Color accent = Color(0xFFB66DFF);

  // --- TEXTES ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF); // Gris froid
  static const Color textTertiary = Color(0xFF4B5563);

  // --- SÉMANTIQUE (Pastel/Néon pour être lisible sur fond sombre) ---
  static const Color success = Color(0xFF10B981); // Vert émeraude
  static const Color successLight = Color(0xFF2EBD85); // Vert clair pour backgrounds
  static const Color error = Color(0xFFEF4444);   // Rouge vif
  static const Color errorLight = Color(0xFFEC4899); // Rose/magenta pour backgrounds
  static const Color warning = Color(0xFFF59E0B); // Ambre
  static const Color warningLight = Color(0xFFFCA5A5); // Orange clair pour backgrounds

  // --- VARIANTS (Utilisation dans les overlays, backgrounds, etc.) ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // --- OVERLAYS & SEMI-TRANSPARENTS ---
  static Color whiteOverlay05 = white.withValues(alpha: AppOpacities.subtle);
  static Color whiteOverlay10 = white.withValues(alpha: AppOpacities.lightOverlay);
  static Color whiteOverlay15 = white.withValues(alpha: AppOpacities.surfaceTint);
  static Color whiteOverlay20 = white.withValues(alpha: AppOpacities.border);
  static Color whiteOverlay30 = white.withValues(alpha: AppOpacities.decorative);
  static Color whiteOverlay50 = white.withValues(alpha: AppOpacities.semiVisible);
  static Color whiteOverlay60 = white.withValues(alpha: AppOpacities.prominent);

  static Color blackOverlay05 = black.withValues(alpha: AppOpacities.subtle);
  static Color blackOverlay10 = black.withValues(alpha: AppOpacities.lightOverlay);
  static Color blackOverlay20 = black.withValues(alpha: AppOpacities.border);
  static Color blackOverlay30 = black.withValues(alpha: AppOpacities.decorative);
  static Color blackOverlay50 = black.withValues(alpha: AppOpacities.semiVisible);
  static Color blackOverlay60 = black.withValues(alpha: AppOpacities.prominent);

  // --- ORANGE VARIANTS (pour les avertissements/infos) ---
  static const Color orange = Color(0xFFFF9800);
  static const Color orangeDark = Color(0xFFE65100);
  static const Color orangeLight = Color(0xFFFFE0B2);

  // --- CYAN/TEAL VARIANTS ---
  static const Color cyan = Color(0xFF00BCD4);
  static const Color cyanDark = Color(0xFF00838F);

  // --- GRADIENTS ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF3D54CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // MODIFIÉ : Plus de transparence pour l'effet Glassmorphism
  static LinearGradient surfaceGradient = LinearGradient(
    colors: [
      surface.withValues(alpha: 0.70), // 70% d'opacité (Haut gauche)
      surface.withValues(alpha: 0.40), // 40% d'opacité (Bas droite)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- BORDURES (Effet verre) ---
  static Color border = Colors.white.withValues(alpha: 0.08);

  // --- CHART PALETTE (Néons) ---
  static const List<Color> charts = [
    Color(0xFF4B68FF), // Primary Blue
    Color(0xFFB66DFF), // Purple
    Color(0xFF2EBD85), // Green
    Color(0xFFF59E0B), // Orange
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Teal
  ];

}