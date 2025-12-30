import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_icon.dart';
import 'appearance_settings.dart';

class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(icon: Icons.palette_outlined, color: AppColors.accent),
              const SizedBox(width: AppDimens.paddingM),
              Text('Apparence', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          const AppearanceSettings(),
        ],
      ),
    );
  }
}