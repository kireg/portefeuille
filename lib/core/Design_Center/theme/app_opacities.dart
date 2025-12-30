/// Centralize opacity values for consistent transparency
/// Usage: color: Colors.white.withValues(alpha: AppOpacities.high)
class AppOpacities {
  // --- CONTENT VISIBILITY LEVELS ---
  /// Fully visible (100%) - primary content
  static const double full = 1.0;

  /// High visibility (87%) - primary content, important elements
  static const double high = 0.87;

  /// Medium visibility (60%) - secondary content
  static const double medium = 0.60;

  /// Low visibility (38%) - tertiary content, disabled states
  static const double low = 0.38;

  /// Minimal visibility (12%) - hints, placeholders
  static const double minimal = 0.12;

  // --- INTERACTION STATES ---
  /// Hover state (8%) - subtle feedback
  static const double hovered = 0.08;

  /// Focused state (12%) - focus ring feedback
  static const double focused = 0.12;

  /// Pressed state (16%) - active/pressed feedback
  static const double pressed = 0.16;

  /// Disabled state (38%) - disabled elements
  static const double disabled = 0.38;

  // --- OVERLAY/BACKDROP OPACITY ---
  /// Modal/Dialog scrim (32%) - darkens background
  static const double scrim = 0.32;

  /// General overlay (40%) - overlay content
  static const double overlay = 0.4;

  /// Glassmorphism effect (15%) - frosted glass
  static const double glass = 0.15;

  // --- ADVANCED STATES ---
  /// Hover/Focus emphasis (5%) - very subtle
  static const double hoverEmphasis = 0.05;

  /// Selection state (10%) - selection feedback
  static const double selected = 0.10;

  /// Error state (20%) - error emphasis
  static const double errorEmphasis = 0.20;
  
  // --- GRANULAR OPACITY VALUES (for specific use cases) ---
  /// Transparent (0%) - fully transparent
  static const double transparent = 0.0;
  
  /// Subtle background (5%) - very light tint
  static const double subtle = 0.05;
  
  /// Light overlay (10%) - light background tint
  static const double lightOverlay = 0.10;
  
  /// Surface tint (15%) - colored surface tint
  static const double surfaceTint = 0.15;
  
  /// Border/divider (20%) - subtle borders
  static const double border = 0.20;
  
  /// Decorative (30%) - decorative elements
  static const double decorative = 0.30;
  
  /// Shadow (40%) - shadow/elevation
  static const double shadow = 0.40;
  
  /// Semi-visible (50%) - half opacity
  static const double semiVisible = 0.50;
  
  /// Prominent (60%) - prominent secondary
  static const double prominent = 0.60;
  
  /// Strong (70%) - strong emphasis
  static const double strong = 0.70;
  
  /// VeryHigh (80%) - very high visibility
  static const double veryHigh = 0.80;
  
  /// Almost opaque (85%) - almost fully visible
  static const double almostOpaque = 0.85;
  
  /// Near full (90%) - nearly full opacity
  static const double nearFull = 0.90;
}
