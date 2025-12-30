import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour HapticFeedback
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/components/app_tile.dart';
import 'package:portefeuille/core/ui/widgets/primitives/privacy_blur.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_calculation_provider.dart';
import 'package:portefeuille/features/00_app/services/modal_service.dart';

import 'account_tile.dart';

import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

class InstitutionTile extends StatelessWidget {
  final Institution institution;
  const InstitutionTile({super.key, required this.institution});

  @override
  Widget build(BuildContext context) {
    final calculationProvider = context.watch<PortfolioCalculationProvider>();
    final baseCurrency = calculationProvider.currentBaseCurrency;

    // 1. Calcul de la Valeur Totale de l'institution
    final institutionTotalValue = institution.accounts.fold(
        0.0, (sum, acc) => sum + calculationProvider.getConvertedAccountValue(acc.id));

    // 2. Calcul du P/L Total de l'institution
    // Note: Assure-toi que getConvertedAccountPL existe dans PortfolioProvider, sinon utilise 0.0
    final institutionTotalPL = institution.accounts.fold(
        0.0, (sum, acc) => sum + calculationProvider.getConvertedAccountPL(acc.id));

    // Calcul du pourcentage (gestion de la division par zéro)
    final double investedAmount = institutionTotalValue - institutionTotalPL;
    final double institutionPLPercent = (investedAmount != 0)
        ? institutionTotalPL / investedAmount
        : 0.0;

    final isPositive = institutionTotalPL >= 0;
    final plColor = isPositive ? AppColors.success : AppColors.error;

    return AppCard(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      isGlass: true,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded) HapticFeedback.lightImpact();
          },
          tilePadding: AppSpacing.expansionTilePaddingDefault,
          // Icône de gauche (Banque)
          leading: Builder(
            builder: (context) {
              String? logoPath;
              final normalized = institution.name.toLowerCase().replaceAll(' ', '_');
              if (normalized.contains('boursorama')) {
                logoPath = 'assets/logos/boursorama.png';
              } else if (normalized.contains('trade_republic')) {
                logoPath = 'assets/logos/trade_republic.png';
              } else if (normalized.contains('revolut')) {
                logoPath = 'assets/logos/revolut.png';
              } else if (normalized.contains('degiro')) {
                logoPath = 'assets/logos/degiro.png';
              } else if (normalized.contains('interactive_brokers')) {
                logoPath = 'assets/logos/interactive_brokers.png';
              } else if (normalized.contains('binance')) {
                logoPath = 'assets/logos/binance.png';
              } else if (normalized.contains('coinbase')) {
                logoPath = 'assets/logos/coinbase.png';
              } else if (normalized.contains('kraken')) {
                logoPath = 'assets/logos/kraken.png';
              } else if (normalized.contains('fortuneo')) {
                logoPath = 'assets/logos/fortuneo.png';
              } else if (normalized.contains('credit_agricole')) {
                logoPath = 'assets/logos/credit_agricole.png';
              } else if (normalized.contains('bnp')) {
                logoPath = 'assets/logos/bnp_paribas.png';
              } else if (normalized.contains('societe_generale')) {
                logoPath = 'assets/logos/societe_generale.png';
              }

              if (logoPath != null) {
                return Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS + 4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Image.asset(
                    logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, color: AppColors.primary),
                  ),
                );
              }

              return AppIcon(
                icon: Icons.account_balance,
                backgroundColor: AppColors.primary.withValues(alpha: AppOpacities.lightOverlay),
                color: AppColors.primary,
              );
            }
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
                  PrivacyBlur(
                    child: Text(
                      CurrencyFormatter.format(institutionTotalValue, baseCurrency),
                      style: AppTypography.bodyBold,
                    ),
                  ),
                  AppSpacing.gapTiny,
                  // Ligne P/L (Montant + %)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: plColor,
                        size: AppComponentSizes.iconXSmall,
                      ),
                      // CORRECTION ICI : Suppression de compact: true
                      PrivacyBlur(
                        child: Text(
                          CurrencyFormatter.format(institutionTotalPL, baseCurrency),
                          style: AppTypography.caption.copyWith(
                            color: plColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      AppSpacing.gapH4,
                      Text(
                        '(${NumberFormat.decimalPercentPattern(decimalDigits: 1).format(institutionPLPercent)})',
                        style: AppTypography.caption.copyWith(
                            color: plColor.withValues(alpha: AppOpacities.veryHigh)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: AppDimens.paddingS),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) {
                  if (value == 'edit') {
                    ModalService.showAddInstitution(context, institutionToEdit: institution);
                  } else if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceLight,
                        title: Text('Supprimer ${institution.name} ?', style: AppTypography.h3),
                        content: Text(
                          'Cette action supprimera également tous les comptes et transactions associés. Cette action est irréversible.',
                          style: AppTypography.body,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('Annuler', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<PortfolioProvider>().deleteInstitution(institution.id);
                              Navigator.of(ctx).pop();
                            },
                            child: Text('Supprimer', style: AppTypography.label.copyWith(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: AppComponentSizes.iconMediumSmall, color: AppColors.textPrimary),
                        AppSpacing.gapHorizontalSmall,
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: AppComponentSizes.iconMediumSmall, color: AppColors.error),
                        AppSpacing.gapHorizontalSmall,
                        Text('Supprimer', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
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
              leading: const Icon(Icons.add_circle_outline, size: AppComponentSizes.iconSmall, color: AppColors.textSecondary),
              onTap: () => ModalService.showAddAccount(context, institutionId: institution.id),
            ),
          ],
        ),
      ),
    );
  }
}