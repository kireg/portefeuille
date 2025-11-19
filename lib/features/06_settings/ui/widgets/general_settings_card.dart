import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

class GeneralSettingsCard extends StatelessWidget {
  const GeneralSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTheme.buildStyledCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.buildSectionHeader(
            context: context,
            icon: Icons.tune_outlined,
            title: 'Préférences Générales',
          ),
          const SizedBox(height: 8),
          // Ajoutez ici les widgets spécifiques aux préférences générales
        ],
      ),
    );
  }
}
