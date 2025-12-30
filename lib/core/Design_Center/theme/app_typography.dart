import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Hero (ex: Solde total du portefeuille)
  static TextStyle hero = GoogleFonts.manrope(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.1,
  );

  // H1 (Titres d'écrans)
  static TextStyle h1 = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // H2 (Titres de section)
  static TextStyle h2 = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // H3 (Sous-titres importants, noms d'actifs)
  static TextStyle h3 = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body (Texte standard)
  static TextStyle body = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Body Bold (Valeurs dans les listes)
  static TextStyle bodyBold = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Caption (Petits textes, labels, dates)
  static TextStyle caption = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );

  // Label (Boutons, Tags)
  static TextStyle label = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  // --- PETITES TAILLES ADDITIONNELLES ---
  // Micro (Ex: Badges, small indicators)
  static TextStyle micro = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );

  // Small (Ex: Helpers, infos secondaires)
  static TextStyle small = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // --- VARIANTS AVEC COLORATION ---
  // Body avec couleur personnalisée (utile pour les états)
  static TextStyle bodyWithColor(Color color) => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: color,
    height: 1.5,
  );

  // Caption colorisé
  static TextStyle captionWithColor(Color color) => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color,
  );
}