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
import 'package:portefeuille/features/00_app/providers/portfolio_calculation_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/data/models/asset_type.dart'; // AJOUT

// Widgets & Dialogs refactorisés
import 'package:portefeuille/features/04_journal/ui/dialogs/asset_dialogs.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/asset_card.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/summary_empty_state.dart';

class SyntheseView extends StatefulWidget {
  const SyntheseView({super.key});

  @override
  State<SyntheseView> createState() => _SyntheseViewState();
}

class _SyntheseViewState extends State<SyntheseView> {
  final Set<AssetType> _selectedFilters = {};

  @override
  Widget build(BuildContext context) {
    // Calcul du padding pour aligner le titre sous la navbar/status bar
    final double topPadding = MediaQuery.of(context).padding.top + 90;

    return Consumer3<PortfolioProvider, PortfolioCalculationProvider, SettingsProvider>(
      builder: (context, portfolioProvider, calculationProvider, settingsProvider, child) {
        final baseCurrency = settingsProvider.baseCurrency;
        var aggregatedAssets = calculationProvider.aggregatedAssets;
        final isProcessing = portfolioProvider.isProcessingInBackground || calculationProvider.isCalculating;

        if (portfolioProvider.activePortfolio == null) {
          return const Center(child: Text("Aucun portefeuille sélectionné."));
        }

        // Filtrage
        if (_selectedFilters.isNotEmpty) {
          aggregatedAssets = aggregatedAssets.where((a) => _selectedFilters.contains(a.type)).toList();
        }

        // État Vide (si aucun actif au total, pas juste après filtre)
        if (calculationProvider.aggregatedAssets.isEmpty) {
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
                        padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                        child: Column(
                          children: [
                            Center(child: Text('Synthèse', style: AppTypography.h2)),
                            const SizedBox(height: AppDimens.paddingM),
                            // Filtres
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                              child: Row(
                                children: AssetType.values.map((type) {
                                  final isSelected = _selectedFilters.contains(type);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      label: Text(type.displayName),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedFilters.add(type);
                                          } else {
                                            _selectedFilters.remove(type);
                                          }
                                        });
                                      },
                                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                      checkmarkColor: AppColors.primary,
                                      labelStyle: TextStyle(
                                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
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
                                  portfolioProvider,
                                ),
                                onEditYield: () => AssetDialogs.showEditYieldDialog(
                                  context,
                                  asset,
                                  portfolioProvider,
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
                    color: Colors.black.withValues(alpha: 0.5),
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