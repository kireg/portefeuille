import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour HapticFeedback
import 'package:intl/intl.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:provider/provider.dart';

import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/components/app_tile.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/services/modal_service.dart';

import 'account_tile.dart'; // On garde celui-ci pour l'instant, on le migrera en phase 4

class InstitutionTile extends StatelessWidget {
  final Institution institution;
  const InstitutionTile({super.key, required this.institution});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final baseCurrency = provider.currentBaseCurrency;

    // Calculs
    final institutionTotalValue = institution.accounts.fold(
        0.0, (sum, acc) => sum + provider.getConvertedAccountValue(acc.id));

    return AppCard(
      padding: EdgeInsets.zero, // On gère le padding en interne pour le collage des bords
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded) HapticFeedback.lightImpact();
          },
          tilePadding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingS
          ),
          leading: AppIcon(
            icon: Icons.account_balance,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            color: AppColors.primary,
          ),
          title: Text(
            institution.name,
            style: AppTypography.h3,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.format(institutionTotalValue, baseCurrency),
                style: AppTypography.bodyBold,
              ),
              const SizedBox(width: AppDimens.paddingS),
              const Icon(Icons.expand_more, color: AppColors.textTertiary),
            ],
          ),
          children: [
            // Ligne de séparation subtile
            Divider(height: 1, color: AppColors.border),

            // Liste des comptes
            ...institution.accounts.map((account) {
              return AccountTile(
                institutionId: institution.id,
                account: account,
                baseCurrency: baseCurrency,
                accountCurrency: account.activeCurrency,
              );
            }),

            // Bouton "Ajouter" en bas de liste
            AppTile(
              title: 'Ajouter un compte',
              leading: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.textSecondary),
              onTap: () => ModalService.showAddAccount(context, institutionId: institution.id),
            ),
          ],
        ),
      ),
    );
  }
}