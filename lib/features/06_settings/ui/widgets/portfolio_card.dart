// lib/features/06_settings/ui/widgets/portfolio_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';
import 'package:portefeuille/features/01_launch/ui/widgets/initial_setup_wizard.dart';

class PortfolioCard extends StatelessWidget {
  const PortfolioCard({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = context.watch<PortfolioProvider>();
    final theme = Theme.of(context);

    return AppTheme.buildStyledCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.buildSectionHeader(
            context: context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Portefeuille',
          ),
          const SizedBox(height: 16),
          AppTheme.buildInfoContainer(
            context: context,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Actif', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        portfolioProvider.activePortfolio?.name ?? 'Aucun',
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (portfolioProvider.portfolios.length > 1)
                  PopupMenuButton<Portfolio>(
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'Changer',
                    onSelected: (portfolio) =>
                        portfolioProvider.setActivePortfolio(portfolio.id),
                    itemBuilder: (context) => portfolioProvider.portfolios
                        .map((p) => PopupMenuItem(
                              value: p,
                              child: Text(p.name),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau'),
                onPressed: () => _showNewPortfolioDialog(context, portfolioProvider),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Renommer'),
                onPressed: portfolioProvider.activePortfolio == null
                    ? null
                    : () => _showRenameDialog(context, portfolioProvider),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Supprimer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: portfolioProvider.activePortfolio == null
                    ? null
                    : () => portfolioProvider
                        .deletePortfolio(portfolioProvider.activePortfolio!.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, PortfolioProvider provider) {
    final nameController =
        TextEditingController(text: provider.activePortfolio?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nouveau nom'),
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            child: const Text('Enregistrer'),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                provider.renameActivePortfolio(name);
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showNewPortfolioDialog(BuildContext context, PortfolioProvider provider) {
    final nameController = TextEditingController(text: "Nouveau Portefeuille");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau portefeuille'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comment créer votre portefeuille ?'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(ctx),
          ),
          OutlinedButton(
            child: const Text('Vide'),
            onPressed: () {
              provider.addNewPortfolio(nameController.text.trim().isEmpty
                  ? "Nouveau Portefeuille"
                  : nameController.text.trim());
              Navigator.pop(ctx);
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.assistant_outlined, size: 18),
            label: const Text('Assistant'),
            onPressed: () async {
              final name = nameController.text.trim().isEmpty
                  ? "Nouveau Portefeuille"
                  : nameController.text.trim();
              Navigator.pop(ctx);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InitialSetupWizard(portfolioName: name),
                ),
              );
              
              // Si le wizard a terminé avec succès, on ferme les paramètres pour revenir à l'accueil
              if (result == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}

