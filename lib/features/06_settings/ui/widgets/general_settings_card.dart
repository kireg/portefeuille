import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/components/app_tile.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

class GeneralSettingsCard extends StatelessWidget {
  const GeneralSettingsCard({super.key});

  static const List<String> _baseCurrencies = ['EUR', 'USD', 'GBP', 'CHF', 'JPY', 'CAD'];

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(icon: Icons.tune_outlined, color: AppColors.primary),
              const SizedBox(width: AppDimens.paddingM),
              Text('Préférences', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),

          // Devise
          AppTile(
            title: 'Devise de base',
            subtitle: 'Devise principale pour les totaux',
            leading: const Icon(Icons.currency_exchange, color: AppColors.textSecondary, size: 20),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settingsProvider.baseCurrency,
                dropdownColor: AppColors.surfaceLight,
                style: AppTypography.bodyBold,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.textTertiary),
                onChanged: (val) {
                  if (val != null) settingsProvider.setBaseCurrency(val);
                },
                items: _baseCurrencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
              ),
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // Niveau
          AppTile(
            title: 'Niveau utilisateur',
            subtitle: 'Affiche des aides contextuelles',
            leading: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<UserLevel>(
                value: settingsProvider.userLevel,
                dropdownColor: AppColors.surfaceLight,
                style: AppTypography.bodyBold,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.textTertiary),
                onChanged: (val) {
                  if (val != null) settingsProvider.setUserLevel(val);
                },
                items: UserLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level.name.toUpperCase()),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}