import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core UI
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';

// Logic
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

// Widgets
import 'widgets/crowdfunding_planner_widget.dart';
import 'widgets/crowdfunding_timeline_widget.dart';
import 'widgets/crowdfunding_map_widget.dart';
import 'widgets/crowdfunding_projection_chart.dart';

class CrowdfundingTrackingTab extends StatelessWidget {
  const CrowdfundingTrackingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        final portfolio = portfolioProvider.activePortfolio;

        if (portfolio == null) {
          return const Center(child: Text("Aucun portefeuille sélectionné."));
        }

        return AppScreen(
          withSafeArea: false,
          body: CustomScrollView(
            slivers: [
              // Titre
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingL),
                  child: Center(child: Text('Suivi Crowdfunding', style: AppTypography.h2)),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Résumé / KPI
                    const FadeInSlide(
                      delay: 0.1,
                      child: CrowdfundingPlannerWidget(),
                    ),

                    const SizedBox(height: AppDimens.paddingM),

                    // 2. Timeline des remboursements
                    const FadeInSlide(
                      delay: 0.15,
                      child: CrowdfundingTimelineWidget(),
                    ),

                    const SizedBox(height: AppDimens.paddingM),

                    // 3. Projection (Graphique)
                    FadeInSlide(
                      delay: 0.2,
                      child: CrowdfundingProjectionChart(
                        assets: portfolio.institutions
                            .expand((i) => i.accounts)
                            .expand((a) => a.assets)
                            .toList(),
                        transactions: portfolio.institutions
                            .expand((i) => i.accounts)
                            .expand((a) => a.transactions)
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: AppDimens.paddingM),

                    // 4. Carte
                    FadeInSlide(
                      delay: 0.25,
                      child: CrowdfundingMapWidget(
                        assets: portfolio.institutions
                            .expand((i) => i.accounts)
                            .expand((a) => a.assets)
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 100), // Padding pour la BottomNavBar
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
