// lib/features/06_settings/ui/widgets/portfolio_management_settings.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

class PortfolioManagementSettings extends StatelessWidget {
  const PortfolioManagementSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Ce widget a besoin de Consumer pour réagir aux changements (ex: nom, liste)
    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion du Portefeuille',
              style: theme.textTheme.titleMedium,
            ),
            ListTile(
              title: const Text('Portefeuille Actif'),
              trailing: DropdownButton<Portfolio>(
                value: portfolioProvider.activePortfolio,
                onChanged: (Portfolio? newValue) {
                  if (newValue != null) {
                    portfolioProvider.setActivePortfolio(newValue.id);
                  }
                },
                items: portfolioProvider.portfolios
                    .map<DropdownMenuItem<Portfolio>>((Portfolio portfolio) {
                  return DropdownMenuItem<Portfolio>(
                    value: portfolio,
                    child: Text(portfolio.name),
                  );
                }).toList(),
              ),
            ),
            Row(
              // --- CORRECTION DE L'ERREUR ---
              // mainAxisAlignment est maintenant un paramètre nommé
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add_outlined),
                  label: const Text('Nouveau'),
                  onPressed: () {
                    // TODO: Ajouter un dialogue pour demander le nom
                    portfolioProvider.addNewPortfolio("Nouveau Portefeuille");
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.edit_outlined, color: Colors.grey[300]),
                  label: Text('Renommer',
                      style: TextStyle(color: Colors.grey[300])),
                  onPressed: portfolioProvider.activePortfolio == null
                      ? null
                      : () => _showRenameDialog(context, portfolioProvider),
                ),
                TextButton.icon(
                  icon: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error),
                  label: Text('Supprimer',
                      style: TextStyle(color: theme.colorScheme.error)),
                  onPressed: portfolioProvider.activePortfolio == null
                      ? null
                      : () {
                    // TODO: Ajouter confirmation
                    portfolioProvider.deletePortfolio(
                        portfolioProvider.activePortfolio!.id);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, PortfolioProvider provider) {
    final nameController =
    TextEditingController(text: provider.activePortfolio?.name ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Renommer le portefeuille'),
          content: TextFormField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nouveau nom'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom ne peut pas être vide';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Enregistrer'),
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  provider.renameActivePortfolio(newName);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}