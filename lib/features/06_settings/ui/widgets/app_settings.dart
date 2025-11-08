// lib/features/06_settings/ui/widgets/app_settings.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

class AppSettings extends StatelessWidget {
  const AppSettings({super.key});

  @override
  Widget build(BuildContext context) {
    // Utilise Consumer car ces paramètres peuvent changer
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Column(
          children: [
            SwitchListTile.adaptive(
              title: const Text('Mode en ligne'),
              subtitle: const Text('Mise à jour des prix, analyse IA, etc.'),
              value: settingsProvider.isOnlineMode,
              onChanged: (bool value) {
                settingsProvider.toggleOnlineMode(value);
              },
              activeTrackColor: Theme.of(context).colorScheme.primary,
            ),
            const Divider(),
            ListTile(
              title: const Text('Niveau d\'utilisateur'),
              trailing: DropdownButton<UserLevel>(
                value: settingsProvider.userLevel,
                onChanged: (UserLevel? newValue) {
                  if (newValue != null) {
                    settingsProvider.setUserLevel(newValue);
                  }
                },
                items: UserLevel.values
                    .map<DropdownMenuItem<UserLevel>>((UserLevel value) {
                  return DropdownMenuItem<UserLevel>(
                    value: value,
                    child: Text(value.toString().split('.').last),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}