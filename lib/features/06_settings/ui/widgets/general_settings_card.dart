import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
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
          const SizedBox(height: AppDimens.paddingL),

          // Devise de base
          AppDropdown<String>(
            label: 'Devise de base',
            value: settingsProvider.baseCurrency,
            items: _baseCurrencies.map((currency) {
              return DropdownMenuItem(
                value: currency,
                child: Text(currency),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) settingsProvider.setBaseCurrency(val);
            },
            prefixIcon: Icons.currency_exchange,
          ),

          const SizedBox(height: AppDimens.paddingM),

          // Niveau Utilisateur
          AppDropdown<UserLevel>(
            label: 'Niveau utilisateur',
            value: settingsProvider.userLevel,
            items: UserLevel.values.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(level.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) settingsProvider.setUserLevel(val);
            },
            prefixIcon: Icons.person_outline,
          ),

          const SizedBox(height: AppDimens.paddingL),

          Text('Priorité des sources de données', style: AppTypography.label),
          const SizedBox(height: AppDimens.paddingS),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              children: [
                for (int index = 0; index < settingsProvider.serviceOrder.length; index++)
                  ListTile(
                    key: ValueKey(settingsProvider.serviceOrder[index]),
                    title: Text(settingsProvider.serviceOrder[index], style: AppTypography.body),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle, color: AppColors.textSecondary),
                    ),
                    trailing: index == 0 
                        ? const Icon(Icons.star, size: AppComponentSizes.iconXSmall, color: AppColors.primary) 
                        : null,
                  ),
              ],
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final List<String> newOrder = List.from(settingsProvider.serviceOrder);
                final String item = newOrder.removeAt(oldIndex);
                newOrder.insert(newIndex, item);
                settingsProvider.setServiceOrder(newOrder);
              },
            ),
          ),
        ],
      ),
    );
  }
}