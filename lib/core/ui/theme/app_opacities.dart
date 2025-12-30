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
}
