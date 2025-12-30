import 'package:flutter/material.dart';

/// Centralize animation durations and curves for consistent motion
/// Usage: duration: AppAnimations.normal
class AppAnimations {
  // --- DURATIONS ---
  /// Fast animations (100ms) - micro interactions, subtle effects
  static const Duration fast = Duration(milliseconds: 100);

  /// Normal animations (200ms) - standard interactions, state changes
  static const Duration normal = Duration(milliseconds: 200);

  /// Slow animations (300ms) - emphasis, navigation transitions
  static const Duration slow = Duration(milliseconds: 300);

  /// Slower animations (500ms) - page transitions, complex animations
  static const Duration slower = Duration(milliseconds: 500);

  /// Slowest animations (1500ms) - value counters, complex sequences
  static const Duration slowest = Duration(milliseconds: 1500);

  /// Normal in milliseconds (200) - for decimal conversions
  static const int normalMs = 200;

  // --- CURVES (Easing Functions) ---
  /// Linear motion - used sparingly
  static const Curve linear = Curves.linear;

  /// Ease in out quad - standard Material curve
  static const Curve easeInOutQuad = Curves.easeInOutQuad;

  /// Ease out quad - deceleration, landing effect
  static const Curve easeOutQuad = Curves.easeOutQuad;

  /// Ease out back - spring-like effect
  static const Curve curveEaseOutBack = Curves.easeOutBack;

  /// Custom cubic bezier - premium feel
  static const Curve easeInOutCubic = Cubic(0.645, 0.045, 0.355, 1.0);

  /// Custom cubic bezier - quart easing
  static const Curve easeOutQuart = Cubic(0.165, 0.84, 0.44, 1.0);

  /// Custom cubic bezier - smooth deceleration
  static const Curve easeInQuad = Cubic(0.11, 0, 0.5, 0);

  // --- DELAYS (for staggered animations) ---
  /// Fast delay (100ms) - quick stagger
  static const Duration delayFast = Duration(milliseconds: 100);

  /// Small delay (50ms) - slight stagger
  static const Duration delayS = Duration(milliseconds: 50);

  /// Medium delay (100ms) - standard stagger
  static const Duration delayM = Duration(milliseconds: 100);

  /// Large delay (200ms) - pronounced stagger
  static const Duration delayL = Duration(milliseconds: 200);

  /// Tooltip delay (500ms) - before showing tooltips
  static const Duration delayTooltip = Duration(milliseconds: 500);

  // --- CONVENIENT COMBINATIONS ---
  /// Fast + Linear - snappy interactions
  static const Duration fastLinear = fast;

  /// Normal + EaseOutQuad - smooth state changes
  static const Duration normalEaseOut = normal;
}
