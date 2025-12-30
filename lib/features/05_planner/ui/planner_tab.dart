import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:provider/provider.dart';

// Core UI
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';

// Logic
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

// Widgets
import 'widgets/savings_plans_section.dart';
import 'widgets/projection_section.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  // L'état de la durée reste ici car il influence la section Projection
  int _selectedDuration = 10;

  @override
  Widget build(BuildContext context) {
    return Selector<PortfolioProvider, Portfolio?>(
      selector: (context, provider) => provider.activePortfolio,
      builder: (context, portfolio, child) {
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
                  child: Center(child: Text('Planification', style: AppTypography.h2)),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Section Plans d'Épargne
                    const FadeInSlide(
                      delay: 0.1,
                      child: SavingsPlansSection(),
                    ),

                    const SizedBox(height: AppDimens.paddingM),

                    // 2. Section Projection (Graphique + Stats)
                    FadeInSlide(
                      delay: 0.2,
                      child: ProjectionSection(
                        selectedDuration: _selectedDuration,
                        onDurationChanged: (duration) {
                          setState(() => _selectedDuration = duration);
                        },
                      ),
                    ),

                    const SizedBox(height: AppDimens.floatingNavBarPaddingBottomFixed),
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