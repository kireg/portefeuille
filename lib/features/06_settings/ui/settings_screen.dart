import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/core/Design_Center/widgets/components/app_screen.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_icon.dart';

import 'tabs/general_settings_tab.dart';
import 'tabs/security_settings_tab.dart';
import 'tabs/advanced_settings_tab.dart';
import 'tabs/about_tab.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusL),
      ),
      child: DefaultTabController(
        length: 4,
        child: AppScreen(
          withSafeArea: false,
          body: Column(
            children: [
              // Header
              Padding(
                padding: AppSpacing.settingsHeaderPaddingDefault,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Paramètres',
                        style: AppTypography.h1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppIcon(
                        icon: Icons.close,
                        onTap: () => Navigator.of(context).pop(),
                        backgroundColor: Colors.transparent,
                        size: AppComponentSizes.iconMedium,
                      ),
                    ),
                  ],
                ),
              ),

              // TabBar
              const TabBar(
                isScrollable: true,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: 'Général'),
                  Tab(text: 'Sécurité'),
                  Tab(text: 'Avancé'),
                  Tab(text: 'À propos'),
                ],
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  children: [
                    // Padding inférieur pour ne pas cacher le contenu par la nav bar flottante
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimens.floatingNavBarPaddingBottomFixed,
                      ),
                      child: const GeneralSettingsTab(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimens.floatingNavBarPaddingBottomFixed,
                      ),
                      child: const SecuritySettingsTab(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimens.floatingNavBarPaddingBottomFixed,
                      ),
                      child: const AdvancedSettingsTab(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimens.floatingNavBarPaddingBottomFixed,
                      ),
                      child: const AboutTab(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}