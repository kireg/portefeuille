import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_icon.dart';

class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _showAboutSheet(context),
      child: Row(
        children: [
          const AppIcon(icon: Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('À propos', style: AppTypography.h3),
                Text(
                  'Banques supportées, version, etc.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AboutSheet(),
    );
  }
}

class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusL)),
      ),
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: AppOpacities.decorative),
                borderRadius: BorderRadius.circular(AppDimens.radiusXs),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingL),
          Text('À propos de My Invests', style: AppTypography.h2),
          const SizedBox(height: AppDimens.paddingL),
          
          _buildSection(
            'Banques supportées (Import PDF)',
            [
              'Boursobanque',
              'Revolut',
              'Trade Republic',
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          
          _buildSection(
            'Crowdfunding Immobilier',
            [
              'La Première Brique (Import Excel)',
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          
          _buildSection(
            'Informations',
            [
              'Version: 1.0.2',
              'Développé avec Flutter',
            ],
          ),
          
          const SizedBox(height: AppDimens.paddingXL),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h3.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppDimens.paddingS),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, size: AppComponentSizes.iconXSmall, color: AppColors.success),
              AppSpacing.gapHorizontalSmall,
              Text(item, style: AppTypography.body),
            ],
          ),
        )),
      ],
    );
  }
}
