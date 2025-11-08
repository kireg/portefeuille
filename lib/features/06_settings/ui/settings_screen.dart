// lib/features/06_settings/ui/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

// Imports des nouveaux widgets
import 'widgets/app_settings.dart';
import 'widgets/appearance_settings.dart';
import 'widgets/portfolio_management_settings.dart';
import 'widgets/reset_app_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Le Consumer est nécessaire pour que les widgets enfants aient accès
    // aux providers sans avoir à les passer en paramètre.
    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // <-- CORRIGÉ
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Paramètres',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // 1. Widget d'Apparence (Couleurs)
                const AppearanceSettings(),
                const Divider(),

                // 2. Widget de Gestion de Portefeuille
                // (C'est ici que l'erreur de syntaxe Row a été corrigée)
                const PortfolioManagementSettings(),
                const Divider(),

                // 3. Widget des Paramètres de l'App
                const AppSettings(),
                const Divider(),

                const SizedBox(height: 16),

                // 4. Widget de Réinitialisation
                const ResetAppSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}