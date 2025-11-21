// lib/features/04_summary/ui/synthese_view.dart

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

// Core UI
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';

// Logic
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

// Widgets & Dialogs refactorisés
import 'package:portefeuille/features/04_journal/ui/dialogs/asset_dialogs.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/asset_card.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/summary_empty_state.dart';

class SyntheseView extends StatelessWidget {
  const SyntheseView({super.key});

  @override
  Widget build(BuildContext context) {
    // Calcul du padding pour aligner le titre sous la navbar/status bar
    final double topPadding = MediaQuery.of(context).padding.top + 90;

    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final baseCurrency = provider.currentBaseCurrency;
        final aggregatedAssets = provider.aggregatedAssets;
        final isProcessing = provider.isProcessingInBackground;

        if (provider.activePortfolio == null) {
          return const Center(child: Text("Aucun portefeuille sélectionné."));
        }

        // État Vide
        if (aggregatedAssets.isEmpty) {
          return AppScreen(
            withSafeArea: false,
            body: SummaryEmptyState(topPadding: topPadding),
          );
        }

        // Liste des actifs
        return AppScreen(
          withSafeArea: false,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Titre
                  SliverPadding(
                    padding: EdgeInsets.only(top: topPadding),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppDimens.paddingL),
                        child: Center(child: Text('Synthèse', style: AppTypography.h2)),
                      ),
                    ),
                  ),

                  // Liste
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.paddingM, 0, AppDimens.paddingM, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final asset = aggregatedAssets[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                            child: FadeInSlide(
                              delay: index * 0.05,
                              child: AssetCard(
                                asset: asset,
                                baseCurrency: baseCurrency,
                                onEditPrice: () => AssetDialogs.showEditPriceDialog(
                                  context,
                                  asset,
                                  provider,
                                ),
                                onEditYield: () => AssetDialogs.showEditYieldDialog(
                                  context,
                                  asset,
                                  provider,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: aggregatedAssets.length,
                      ),
                    ),
                  ),
                ],
              ),

              // Overlay de chargement
              if (isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: AppCard(
                        padding: const EdgeInsets.all(AppDimens.paddingL),
                        backgroundColor: AppColors.surface,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(height: AppDimens.paddingM),
                            Text('Calcul en cours...', style: AppTypography.bodyBold),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}