// lib/features/07_management/ui/screens/ai_import_config_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/feedback/premium_help_button.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_dropdown.dart'; // Usage du widget standardisé
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/07_management/ui/screens/import_transaction_screen.dart';


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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusL),
      ),
      child: AppScreen(
        withSafeArea: false,
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.paddingL,
                  AppDimens.paddingL,
                  AppDimens.paddingM,
                  AppDimens.paddingM
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Import Intelligent',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const PremiumHelpButton(
                      title: "Guide Import IA",
                      content: "L'import intelligent utilise l'IA pour analyser n'importe quel document financier (PDF ou Image).\n\n1. Sélectionnez le compte de destination.\n2. Importez votre document.\n3. Sélectionnez la zone contenant les transactions.\n4. L'IA extrait automatiquement les données.",
                      visual: Icon(Icons.auto_awesome, size: 48, color: AppColors.primary),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppIcon(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(),
                      backgroundColor: Colors.transparent,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                children: [
                  FadeInSlide(
                    delay: 0.1,
                    child: AppCard(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Configuration", style: AppTypography.h2),
                          const SizedBox(height: AppDimens.paddingS),
                          Text(
                            "Sélectionnez le compte de destination pour les transactions détectées.",
                            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppDimens.paddingL),

                          // Sélecteur standardisé
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

                  // Zone d'avertissement stylisée
                  FadeInSlide(
                    delay: 0.2,
                    child: Container(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.security, color: AppColors.warning, size: 32),
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
                    delay: 0.3,
                    child: CheckboxListTile(
                      value: _hasAcceptedWarning,
                      onChanged: (val) => setState(() => _hasAcceptedWarning = val ?? false),
                      title: Text("J'ai compris", style: AppTypography.body),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                    ),
                  ),
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
      ),
    );
  }
}