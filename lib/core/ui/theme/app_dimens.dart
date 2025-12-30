class AppDimens {
  // Paddings
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Radius (Arrondis)
  static const double radiusS = 8.0;  // Boutons petits / Tags
  static const double radiusM = 16.0; // Cartes standards
  static const double radiusL = 24.0; // Bottom Sheets / Grandes cartes

  // ─────────────────────────────────────────────────────────────
  // Tab Bars Heights (pour les écrans avec TabBar)
  // ─────────────────────────────────────────────────────────────
  static const double tabBarHeight = 56.0; // Hauteur standard d'une TabBar Material
  static const double floatingAppBarHeight = 60.0; // Hauteur barre flottante Dashboard
  static const double floatingAppBarMargin = paddingS / 2; // paddingS / 2 = 4.0
  static const double floatingNavBarHeight = 80.0; // Hauteur barre nav flottante

  /// Padding TOP pour les écrans avec AppBar flottante supérieure (Dashboard)
  /// = SafeArea (dépend du device) + hauteur AppBar (60) + marge (4) + air (20)
  /// Utiliser: MediaQuery.of(context).padding.top + AppDimens.floatingAppBarPaddingTop
  static const double floatingAppBarPaddingTopFixed = 90.0; // SafeArea + bar + margin + air

  /// Padding BOTTOM pour les écrans avec barre de navigation flottante
  /// = hauteur nav bar (80) + marge (4) + un peu d'air (8)
  static const double floatingNavBarPaddingBottomFixed = 92.0; // hauteur nav + padding
}