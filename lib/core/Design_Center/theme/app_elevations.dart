import 'package:flutter/material.dart';

/// Centralize shadow definitions for consistent elevation effects
/// Usage: decoration: BoxDecoration(boxShadow: AppElevations.md)
class AppElevations {
  // No shadows - flat design
  static const List<BoxShadow> none = [];

  // Small elevation - subtle shadows for hover states
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D000000), // 5% black
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  // Medium elevation - standard card/button shadows
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000), // 10% black
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  // Large elevation - prominent elements
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x26000000), // 15% black
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // Extra large elevation - modals, dialogs
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x33000000), // 20% black
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  /// Colored shadow - useful for button states
  /// Example: AppElevations.colored(AppColors.primary, opacity: 0.4)
  static List<BoxShadow> colored(Color color, {double opacity = 0.4}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  /// Colored shadow with custom blur - for custom effects
  static List<BoxShadow> coloredCustom(
    Color color, {
    double opacity = 0.4,
    Offset offset = const Offset(0, 4),
    double blurRadius = 8,
    double spreadRadius = 0,
  }) =>
      [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          offset: offset,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ];
}
