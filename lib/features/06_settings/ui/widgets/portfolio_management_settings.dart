// lib/features/06_settings/ui/widgets/portfolio_management_settings.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/01_launch/ui/widgets/initial_setup_wizard.dart';

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
              title: const Text(
                'Portefeuille Actif',
                overflow: TextOverflow.ellipsis,
              ),
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
                    child: Text(
                      portfolio.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
            Wrap(
              // --- CORRECTION DE L'ERREUR ---
              // mainAxisAlignment est maintenant un paramètre nommé
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8.0,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add_outlined),
                  label: const Text('Nouveau'),
                  onPressed: () => _showNewPortfolioDialog(context, portfolioProvider),
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
                      : () => _showDeleteConfirmation(context, portfolioProvider),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, PortfolioProvider provider) {
    final portfolioName = provider.activePortfolio?.name ?? 'ce portefeuille';
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "$portfolioName" ?\n\n'
            'Cette action est irréversible. Tous les comptes, transactions et actifs '
            'associés à ce portefeuille seront définitivement supprimés.',
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                provider.deletePortfolio(provider.activePortfolio!.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Portefeuille "$portfolioName" supprimé'),
                  ),
                );
              },
              child: const Text('Supprimer'),
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

  void _showNewPortfolioDialog(BuildContext context, PortfolioProvider provider) {
    final nameController = TextEditingController(text: "Nouveau Portefeuille");
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nouveau portefeuille'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Comment souhaitez-vous créer votre nouveau portefeuille ?'),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du portefeuille',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Portefeuille vide'),
              onPressed: () {
                final name = nameController.text.trim().isEmpty 
                    ? "Nouveau Portefeuille" 
                    : nameController.text.trim();
                provider.addNewPortfolio(name);
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.assistant_outlined),
              label: const Text('Assistant'),
              onPressed: () async {
                final name = nameController.text.trim().isEmpty 
                    ? "Nouveau Portefeuille" 
                    : nameController.text.trim();
                Navigator.of(dialogContext).pop();
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => InitialSetupWizard(portfolioName: name),
                  ),
                );
                // Si l'assistant est complété, le nouveau portefeuille est déjà créé
                if (result == true) {
                  // Rien à faire, le wizard a créé le portefeuille
                }
              },
            ),
          ],
        );
      },
    );
  }
}