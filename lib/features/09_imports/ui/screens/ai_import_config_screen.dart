// lib/features/09_imports/ui/screens/ai_import_config_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/Design_Center/widgets/inputs/app_dropdown.dart';
import 'package:portefeuille/core/Design_Center/widgets/fade_in_slide.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/09_imports/ui/screens/import_transaction_screen.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';

/// Écran de configuration pour l'import via IA.
/// Affiché en Modal Bottom Sheet depuis le FileImportWizard.
class AiImportConfigScreen extends StatefulWidget {
  const AiImportConfigScreen({super.key});

  @override
  State<AiImportConfigScreen> createState() => _AiImportConfigScreenState();
}

class _AiImportConfigScreenState extends State<AiImportConfigScreen> {
  String? _selectedAccountId;
  bool _hasAcceptedWarning = false;

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = context.watch<PortfolioProvider>();
    final activePortfolio = portfolioProvider.activePortfolio;

    // Construction de la liste pour AppDropdown
    final List<DropdownMenuItem<String>> accountItems = [];
    if (activePortfolio != null) {
      for (final institution in activePortfolio.institutions) {
        for (final account in institution.accounts) {
          accountItems.add(
            DropdownMenuItem(
              value: account.id,
              child: Text(
                "${institution.name} - ${account.name}",
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body,
              ),
            ),
          );
        }
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
              children: [
                // Explications
                FadeInSlide(
                  delay: 0.1,
                  child: AppCard(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: AppOpacities.lightOverlay),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: AppComponentSizes.iconMedium),
                            ),
                            AppSpacing.gapHorizontalMedium,
                            Expanded(
                              child: Text("Import Intelligent", style: AppTypography.h3),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.paddingM),
                        Text(
                          "L'IA analyse n'importe quel document financier (PDF ou Image) pour en extraire les transactions.\n\n1. Sélectionnez le compte de destination.\n2. Importez votre document.\n3. Sélectionnez la zone contenant les transactions.\n4. L'IA extrait automatiquement les données.",
                          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.paddingL),

                // Sélecteur de compte
                FadeInSlide(
                  delay: 0.15,
                  child: AppCard(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Compte de destination", style: AppTypography.h3),
                        const SizedBox(height: AppDimens.paddingS),
                        Text(
                          "Sélectionnez le compte où les transactions seront enregistrées.",
                          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppDimens.paddingM),
                        AppDropdown<String>(
                          label: "Compte cible",
                          value: _selectedAccountId,
                          items: accountItems,
                          prefixIcon: Icons.account_balance_wallet_outlined,
                          onChanged: (val) => setState(() => _selectedAccountId = val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.paddingL),

                // Zone d'avertissement
                FadeInSlide(
                  delay: 0.2,
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: AppOpacities.lightOverlay),
                      border: Border.all(color: AppColors.warning.withValues(alpha: AppOpacities.decorative)),
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.security, color: AppColors.warning, size: AppComponentSizes.iconLarge),
                        const SizedBox(height: AppDimens.paddingM),
                        Text(
                          "Confidentialité & Sécurité",
                          style: AppTypography.h3.copyWith(color: AppColors.warning),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.paddingS),
                        Text(
                          "L'analyse IA nécessite l'envoi de votre document sur des serveurs externes sécurisés. Bien que nous prenions toutes les précautions, nous vous déconseillons d'envoyer des documents contenant des données personnelles sensibles (Nom, Adresse, IBAN complet).\n\nLes développeurs déclinent toute responsabilité en cas de fuite de données.",
                          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.paddingM),

                FadeInSlide(
                  delay: 0.25,
                  child: CheckboxListTile(
                    value: _hasAcceptedWarning,
                    onChanged: (val) => setState(() => _hasAcceptedWarning = val ?? false),
                    title: Text("J'ai compris et j'accepte les risques", style: AppTypography.body),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),
                ),

                const SizedBox(height: AppDimens.paddingL),
              ],
            ),
          ),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: AppButton(
              label: "Continuer vers l'import",
              icon: Icons.arrow_forward,
              isFullWidth: true,
              onPressed: (_selectedAccountId != null && _hasAcceptedWarning)
                  ? () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ImportTransactionScreen(),
                        ),
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: AppOpacities.decorative),
              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
            ),
          ),
          AppSpacing.gapM,
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Assistant IA',
                  style: AppTypography.h3,
                  textAlign: TextAlign.center,
                ),
              ),
              AppSpacing.gapHXxl,
            ],
          ),
        ],
      ),
    );
  }
}
