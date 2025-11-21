import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';

import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

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
    // On consomme les providers pour que la page se rafraîchisse si besoin
    context.watch<PortfolioProvider>();
    context.watch<SettingsProvider>();

    // CORRECTION : Ajout de ClipRRect pour arrondir les coins supérieurs
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusL), // Utilise le rayon standard (ex: 24.0)
      ),
      child: AppScreen(
        withSafeArea: false, // Géré par le modal ou le parent
        body: Column(
          children: [
            // Header personnalisé avec Stack pour un centrage parfait
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.paddingL,
                  AppDimens.paddingL,
                  AppDimens.paddingM,
                  AppDimens.paddingM
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Le titre centré
                  // On utilise SizedBox pour s'assurer qu'il prend toute la largeur
                  // et permettre au texte de se centrer dedans
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Paramètres',
                      style: AppTypography.h1,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // 2. Le bouton fermer aligné à droite
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppIcon(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(),
                      backgroundColor: Colors.transparent,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Liste des options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                children: const [
                  FadeInSlide(delay: 0.1, child: AppearanceCard()),
                  SizedBox(height: AppDimens.paddingM),
                  FadeInSlide(delay: 0.15, child: GeneralSettingsCard()),
                  SizedBox(height: AppDimens.paddingM),
                  FadeInSlide(delay: 0.2, child: PortfolioCard()),
                  SizedBox(height: AppDimens.paddingM),
                  FadeInSlide(delay: 0.25, child: OnlineModeCard()),
                  SizedBox(height: AppDimens.paddingM),
                  FadeInSlide(delay: 0.3, child: SyncLogsCard()),
                  SizedBox(height: AppDimens.paddingM),
                  FadeInSlide(delay: 0.35, child: BackupCard()),
                  SizedBox(height: AppDimens.paddingM),
                  FadeInSlide(delay: 0.4, child: DangerZoneCard()),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}