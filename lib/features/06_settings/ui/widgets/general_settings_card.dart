import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

class GeneralSettingsCard extends StatelessWidget {
  const GeneralSettingsCard({super.key});

  // Liste des devises de base supportées (récupérée de l'ancien fichier)
  static const List<String> _baseCurrencies = ['EUR', 'USD', 'GBP', 'CHF', 'JPY', 'CAD'];

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

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

          // 1. Sélection de la Devise de Base
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.currency_exchange_outlined),
            title: const Text('Devise de Base'),
            subtitle: const Text('Devise principale pour les totaux'),
            trailing: DropdownButton<String>(
              value: settingsProvider.baseCurrency,
              underline: const SizedBox(),
              onChanged: (val) {
                if (val != null) {
                  settingsProvider.setBaseCurrency(val);
                }
              },
              items: _baseCurrencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 24),

          // 2. Sélection du Niveau d'utilisateur
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: const Text('Niveau d\'utilisateur'),
            subtitle: const Text('Affiche des aides contextuelles'),
            trailing: DropdownButton<UserLevel>(
              value: settingsProvider.userLevel,
              underline: const SizedBox(),
              onChanged: (UserLevel? newValue) {
                if (newValue != null) {
                  settingsProvider.setUserLevel(newValue);
                }
              },
              items: UserLevel.values.map<DropdownMenuItem<UserLevel>>((UserLevel value) {
                return DropdownMenuItem<UserLevel>(
                  value: value,
                  child: Text(value.toString().split('.').last),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}