import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

class PrivacyBlur extends StatelessWidget {
  final Widget child;
  final double sigma;

  const PrivacyBlur({
    super.key,
    required this.child,
    this.sigma = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    final isPrivacyMode = context.select<SettingsProvider, bool>((p) => p.isPrivacyMode);

    if (!isPrivacyMode) {
      return child;
    }

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
