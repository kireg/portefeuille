import 'package:flutter/material.dart';
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Portefeuille Actif', style: AppTypography.caption),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<Portfolio>(
                        value: provider.activePortfolio,
                        isDense: true,
                        dropdownColor: AppColors.surfaceLight,
                        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        onChanged: (newValue) {
                          if (newValue != null) provider.setActivePortfolio(newValue.id);
                        },
                        items: provider.portfolios.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
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
                type: AppButtonType.ghost, // Style discret pour la suppression
                isFullWidth: false,
                onPressed: provider.activePortfolio == null ? null : () => provider.deletePortfolio(provider.activePortfolio!.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // (Les méthodes _showRenameDialog et _showNewPortfolioDialog peuvent rester telles quelles 
  // si vous acceptez qu'elles utilisent les Dialogs Flutter par défaut, 
  // sinon il faudrait aussi refactorer les AlertDialog. Pour l'instant, ça passe.)
  // ... Copiez ici les méthodes _showRenameDialog et _showNewPortfolioDialog de l'ancien fichier ...
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
            onPressed: () {
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