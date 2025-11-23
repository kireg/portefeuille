import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/01_launch/ui/widgets/initial_setup_wizard.dart';

class PortfolioCard extends StatelessWidget {
  const PortfolioCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(icon: Icons.account_balance_wallet_outlined, color: AppColors.primary),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                // Refactoring : Utilisation de AppDropdown
                child: AppDropdown<Portfolio>(
                  label: 'Portefeuille Actif',
                  value: provider.activePortfolio,
                  items: provider.portfolios.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) provider.setActivePortfolio(newValue.id);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingL),

          // Actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: 'Nouveau',
                icon: Icons.add,
                type: AppButtonType.secondary,
                isFullWidth: false,
                onPressed: () => _showNewPortfolioDialog(context, provider),
              ),
              AppButton(
                label: 'Renommer',
                icon: Icons.edit,
                type: AppButtonType.secondary,
                isFullWidth: false,
                onPressed: provider.activePortfolio == null ? null : () => _showRenameDialog(context, provider),
              ),
              AppButton(
                label: 'Supprimer',
                icon: Icons.delete_outline,
                type: AppButtonType.secondary, // Changé de ghost à secondary
                isFullWidth: false,
                textColor: AppColors.error,
                borderColor: AppColors.error, // Bordure rouge
                onPressed: provider.activePortfolio == null 
                    ? null 
                    : () => _showDeleteConfirmation(context, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PortfolioProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Supprimer le portefeuille ?', style: AppTypography.h3),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${provider.activePortfolio?.name}" ?\nCette action est irréversible.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            child: Text('Annuler', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
            onPressed: () {
              provider.deletePortfolio(provider.activePortfolio!.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, PortfolioProvider provider) {
    final nameController = TextEditingController(text: provider.activePortfolio?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Renommer', style: AppTypography.h3),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: AppTypography.body,
          decoration: const InputDecoration(labelText: 'Nouveau nom'),
        ),
        actions: [
          TextButton(child: const Text('Annuler'), onPressed: () => Navigator.pop(ctx)),
          FilledButton(
            child: const Text('Enregistrer'),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                provider.renameActivePortfolio(nameController.text.trim());
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
        backgroundColor: AppColors.surfaceLight,
        title: Text('Nouveau portefeuille', style: AppTypography.h3),
        content: TextField(
          controller: nameController,
          style: AppTypography.body,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        actions: [
          TextButton(child: const Text('Annuler'), onPressed: () => Navigator.pop(ctx)),
          OutlinedButton(
            child: const Text('Vide'),
            onPressed: () {
              provider.addNewPortfolio(nameController.text);
              Navigator.pop(ctx);
            },
          ),
          FilledButton(
            child: const Text('Assistant'),
            onPressed: () async { // Async ajouté
              Navigator.pop(ctx);

              // Appel asynchrone de l'assistant
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InitialSetupWizard(portfolioName: nameController.text),
                ),
              );

              // Vérification du résultat
              if (result == true && context.mounted) {
                // On ferme la modale parente ou on effectue une autre action si nécessaire
                // Note: Ici on est déjà sorti du dialog par le premier Navigator.pop(ctx).
                // Si vous vouliez fermer l'écran Settings, vous pourriez faire Navigator.of(context).pop();
                // Mais généralement on veut juste rester sur l'écran Settings avec le nouveau portefeuille sélectionné.
              }
            },
          ),
        ],
      ),
    );
  }
}