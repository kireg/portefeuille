import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour HapticFeedback
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/components/app_tile.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/services/modal_service.dart';

import 'account_tile.dart';

class InstitutionTile extends StatelessWidget {
  final Institution institution;
  const InstitutionTile({super.key, required this.institution});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final baseCurrency = provider.currentBaseCurrency;

    // 1. Calcul de la Valeur Totale de l'institution
    final institutionTotalValue = institution.accounts.fold(
        0.0, (sum, acc) => sum + provider.getConvertedAccountValue(acc.id));

    // 2. Calcul du P/L Total de l'institution
    // Note: Assure-toi que getConvertedAccountPL existe dans PortfolioProvider, sinon utilise 0.0
    final institutionTotalPL = institution.accounts.fold(
        0.0, (sum, acc) => sum + provider.getConvertedAccountPL(acc.id));

    // Calcul du pourcentage (gestion de la division par zéro)
    final double investedAmount = institutionTotalValue - institutionTotalPL;
    final double institutionPLPercent = (investedAmount != 0)
        ? institutionTotalPL / investedAmount
        : 0.0;

    final isPositive = institutionTotalPL >= 0;
    final plColor = isPositive ? AppColors.success : AppColors.error;

    return AppCard(
      padding: EdgeInsets.zero,
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
          // Icône de gauche (Banque)
          leading: AppIcon(
            icon: Icons.account_balance,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            color: AppColors.primary,
          ),
          // Nom de l'institution
          title: Text(
            institution.name,
            style: AppTypography.h3,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
          // Partie Droite : Montant + P/L + Flèche
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Valeur Totale
                  Text(
                    CurrencyFormatter.format(institutionTotalValue, baseCurrency),
                    style: AppTypography.bodyBold,
                  ),
                  const SizedBox(height: 2),
                  // Ligne P/L (Montant + %)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: plColor,
                        size: 16,
                      ),
                      // CORRECTION ICI : Suppression de compact: true
                      Text(
                        CurrencyFormatter.format(institutionTotalPL, baseCurrency),
                        style: AppTypography.caption.copyWith(
                          color: plColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${NumberFormat.decimalPercentPattern(decimalDigits: 1).format(institutionPLPercent)})',
                        style: AppTypography.caption.copyWith(
                            color: plColor.withValues(alpha: 0.8)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: AppDimens.paddingS),
              const Icon(Icons.expand_more, color: AppColors.textTertiary),
            ],
          ),
          children: [
            Divider(height: 1, color: AppColors.border),
            ...institution.accounts.map((account) {
              return AccountTile(
                institutionId: institution.id,
                account: account,
                baseCurrency: baseCurrency,
                accountCurrency: account.activeCurrency,
              );
            }),
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