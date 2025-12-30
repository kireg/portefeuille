/// Configuration centralisée pour tous les graphiques de l'application
/// 
/// Ce fichier définit les styles visuels des graphiques (fl_chart):
/// - Lissage des courbes (smoothness)
/// - Épaisseur des lignes
/// - Ombres et effets visuels
/// - Styles des tooltips et axes
class AppChartStyles {
  // ─────────────────────────────────────────────────────────────
  // Line Charts - Propriétés des courbes
  // ─────────────────────────────────────────────────────────────
  
  /// Lissage des courbes (0.0 = anguleux, 1.0 = très lisse)
  /// Valeur élevée pour une courbe élégante et agréable à l'œil
  static const double lineCurveSmoothness = 0.45;
  
  /// Nombre de points maximum à afficher sur la courbe (échantillonnage)
  /// Plus ce nombre est bas, plus la courbe est fluide et lisse
  /// Les vraies valeurs restent disponibles au survol (tooltip)
  static const int maxVisualDataPoints = 25;
  
  /// Épaisseur de la ligne principale
  static const double lineWidth = 3.0;
  
  /// Rayon de flou de l'ombre portée sous la courbe (en pixels)
  static const double lineShadowBlurRadius = 10.0;
  
  /// Décalage vertical de l'ombre (Offset Y)
  static const double lineShadowOffsetY = 4.0;
  
  /// Décalage horizontal de l'ombre (Offset X)
  static const double lineShadowOffsetX = 0.0;
  
  // ─────────────────────────────────────────────────────────────
  // Points de données (Dots)
  // ─────────────────────────────────────────────────────────────
  
  /// Afficher les points sur la courbe (false = courbe épurée)
  static const bool showDots = false;
  
  /// Taille des points si affichés
  static const double dotSize = 4.0;
  
  // ─────────────────────────────────────────────────────────────
  // Bar Charts - Propriétés des barres
  // ─────────────────────────────────────────────────────────────
  
  /// Largeur des barres dans les graphiques en barres
  static const double barWidth = 20.0;
  
  /// Rayon d'arrondi des coins des barres
  static const double barBorderRadius = 6.0;
  
  // ─────────────────────────────────────────────────────────────
  // Grid & Axes - Propriétés de la grille et des axes
  // ─────────────────────────────────────────────────────────────
  
  /// Épaisseur des lignes de la grille
  static const double gridLineWidth = 0.5;
  
  /// Épaisseur de la bordure du graphique
  static const double borderWidth = 1.0;
}
