// lib/features/06_settings/ui/widgets/reset_app_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/01_launch/ui/launch_screen.dart';

class ResetAppSection extends StatelessWidget {
  const ResetAppSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.delete_forever),
        label: const Text('Réinitialiser l\'application'),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        onPressed: () => _showResetConfirmationDialog(context),
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
                // On utilise 'listen: false' car on est dans une fonction
                Provider.of<PortfolioProvider>(context, listen: false)
                    .resetAllData();

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