import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'appearance_settings.dart';

class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTheme.buildStyledCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.buildSectionHeader(
            context: context,
            icon: Icons.palette_outlined,
            title: 'Apparence',
          ),
          const SizedBox(height: 16),
          // Reuse the existing AppearanceSettings widget which renders color options
          const AppearanceSettings(),
        ],
      ),
    );
  }
}
