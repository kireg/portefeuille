import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';
import '../../00_app/providers/settings_provider.dart';
import '../../01_launch/ui/launch_screen.dart';

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
            activeTrackColor: theme.colorScheme.primary,
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
          const Divider(),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Réinitialiser l\'application'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () => _showResetConfirmationDialog(context),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Réinitialiser l\'application ?'),
          content: const Text(
              'Toutes vos données seront définitivement effacées. Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text(
                'Réinitialiser',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                // Clear data
                Provider.of<PortfolioProvider>(context, listen: false).clearPortfolio();

                // Navigate to launch screen and remove all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LaunchScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
