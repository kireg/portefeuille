// lib/features/06_settings/ui/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';
import 'widgets/appearance_card.dart';
import 'widgets/general_settings_card.dart';
import 'widgets/portfolio_card.dart';
import 'widgets/sync_logs_card.dart';
import 'widgets/online_mode_card.dart';
import 'widgets/backup_card.dart';
import 'widgets/danger_zone_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PortfolioProvider, SettingsProvider>(
      builder: (context, portfolioProvider, settingsProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Le titre existant
                  AppTheme.buildScreenTitle(
                    context: context,
                    title: 'Paramètres',
                    centered: true,
                  ),
                  // La croix de fermeture positionnée à droite
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const AppearanceCard(),
                  const SizedBox(height: 12),
                  GeneralSettingsCard(), // Note: J'ai retiré 'const' si le constructeur n'est pas const
                  const SizedBox(height: 12),
                  const PortfolioCard(),
                  const SizedBox(height: 12),
                  const OnlineModeCard(),
                  const SizedBox(height: 12),
                  const SyncLogsCard(),
                  const SizedBox(height: 12),
                  const BackupCard(),
                  const SizedBox(height: 12),
                  const DangerZoneCard(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}