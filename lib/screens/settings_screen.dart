import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Paramètres',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            title: const Text('Mode en ligne'),
            subtitle: const Text('Mise à jour des prix, analyse IA, etc.'),
            value: settingsProvider.isOnlineMode,
            onChanged: (bool value) {
              settingsProvider.toggleOnlineMode(value);
            },
             activeColor: theme.colorScheme.primary,
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
              items: UserLevel.values.map<DropdownMenuItem<UserLevel>>((UserLevel value) {
                return DropdownMenuItem<UserLevel>(
                  value: value,
                  child: Text(value.toString().split('.').last),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
