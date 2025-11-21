// lib/features/07_management/ui/screens/ai_import_config_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_dropdown.dart'; // Usage du widget standardisé
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/07_management/ui/screens/import_transaction_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/ai_transaction_review_screen.dart';
import 'package:portefeuille/core/data/models/transaction_extraction_result.dart';

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

    return AppScreen(
      appBar: AppBar(
        title: Text("Import Intelligent", style: AppTypography.h3),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
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

            const SizedBox(height: AppDimens.paddingL),

            // Zone d'avertissement stylisée
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Confidentialité des données",
                          style: AppTypography.bodyBold.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "L'image sera envoyée à l'IA de Google (Gemini) pour analyse.\n\n"
                        "• Masquez vos informations personnelles (Nom, IBAN).\n"
                        "• Aucune image n'est conservée sur nos serveurs.",
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.paddingM),

            // Checkbox personnalisé
            GestureDetector(
              onTap: () => setState(() => _hasAcceptedWarning = !_hasAcceptedWarning),
              child: Row(
                children: [
                  Icon(
                    _hasAcceptedWarning ? Icons.check_box : Icons.check_box_outline_blank,
                    color: _hasAcceptedWarning ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "J'ai compris et je souhaite continuer.",
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.paddingXL),

            AppButton(
              label: "SCANNER LE DOCUMENT",
              icon: Icons.camera_alt_outlined,
              onPressed: (_selectedAccountId != null && _hasAcceptedWarning)
                  ? () => _startScanProcess(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startScanProcess(BuildContext context) async {
    final results = await Navigator.push<List<TransactionExtractionResult>>(
      context,
      MaterialPageRoute(builder: (_) => const ImportTransactionScreen()),
    );

    if (results != null && results.isNotEmpty && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AiTransactionReviewScreen(
            accountId: _selectedAccountId!,
            extractedResults: results,
          ),
        ),
      );
    }
  }
}