import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:provider/provider.dart';

// Core UI
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon_button.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';
import 'package:portefeuille/core/ui/widgets/portfolio_header.dart';

// Features
import '../../00_app/providers/portfolio_provider.dart';
import '../../00_app/providers/portfolio_calculation_provider.dart';
import '../../00_app/services/modal_service.dart';
import 'package:portefeuille/features/03_overview/ui/widgets/portfolio_history_chart.dart';
import 'widgets/allocation_chart.dart';
import 'widgets/asset_type_allocation_chart.dart';
import 'widgets/sync_alerts_card.dart';
import 'package:portefeuille/features/03_overview/ui/widgets/institution_tile.dart';
import 'package:portefeuille/core/ui/widgets/empty_states/app_empty_state.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final calculationProvider = context.watch<PortfolioCalculationProvider>();
    
    final portfolio = provider.activePortfolio;
    final allocation = calculationProvider.aggregatedValueByAssetType;
    final totalValue = calculationProvider.activePortfolioTotalValue;

    if (portfolio == null) {
      return const Center(child: Text("Aucun portefeuille sélectionné."));
    }

    final institutions = portfolio.institutions;

    // Calcul de l'espace nécessaire en haut pour la barre flottante
    // Hauteur Barre (60) + Marge (4) + SafeArea + un peu d'air (20)
    final double topPadding = MediaQuery.of(context).padding.top + AppDimens.floatingAppBarPaddingTopFixed;

    return AppScreen(
      withSafeArea: false, // Important pour que le gradient monte tout en haut
          body: CustomScrollView(
            slivers: [
              // CORRECTION : On pousse le contenu vers le bas ICI
              SliverPadding(
                padding: EdgeInsets.only(top: topPadding),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.overviewHeaderPaddingDefault,
                    child: FadeInSlide(
                      delay: 0.0,
                      child: Text(
                        'Patrimoine',
                        style: AppTypography.h1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),

              // Contenu principal
              SliverPadding(
                padding: AppSpacing.contentHorizontalPaddingDefault,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Header (Total)
                    const FadeInSlide(
                      delay: 0.1,
                      child: PortfolioHeader(),
                    ),
                    const SizedBox(height: AppDimens.paddingM),

                    // 2. Graphique Historique
                    const FadeInSlide(
                      delay: 0.2,
                      child: AppCard(
                        backgroundColor: Colors.transparent,
                        child: PortfolioHistoryChart(),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),

                    // 3. Allocations
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 800) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: FadeInSlide(
                                    delay: 0.3,
                                    child: _buildAllocationCard(portfolio)
                                ),
                              ),
                              const SizedBox(width: AppDimens.paddingM),
                              Expanded(
                                child: FadeInSlide(
                                    delay: 0.35,
                                    child: _buildAssetTypeCard(allocation, totalValue)
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              FadeInSlide(
                                  key: const ValueKey('alloc_chart'),
                                  delay: 0.3,
                                  child: _buildAllocationCard(portfolio)
                              ),
                              const SizedBox(height: AppDimens.paddingM),
                              FadeInSlide(
                                  key: const ValueKey('asset_chart'),
                                  delay: 0.35,
                                  child: _buildAssetTypeCard(allocation, totalValue)
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: AppDimens.paddingM),

                    // 4. Institutions
                    FadeInSlide(
                      delay: 0.4,
                      child: _buildSectionTitle(
                        context,
                        'Structure du Portefeuille',
                        Icons.account_balance,
                        onAdd: () => ModalService.showAddInstitution(context),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingS),

                    if (institutions.isEmpty)
                      FadeInSlide(
                        delay: 0.45,
                        child: AppCard(
                          child: AppEmptyState(
                            title: 'Aucune institution',
                            message: 'Ajoutez votre première banque ou plateforme pour commencer à suivre votre patrimoine.',
                            icon: Icons.account_balance,
                            buttonLabel: 'Ajouter une institution',
                            onAction: () => ModalService.showAddInstitution(context),
                          ),
                        ),
                      )
                    else
                      ...institutions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final institution = entry.value;

                        final double itemDelay = 0.45 + (index * 0.05);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
                          child: FadeInSlide(
                            delay: itemDelay,
                            child: InstitutionTile(institution: institution),
                          ),
                        );
                      }),

                    // 5. Alertes + Espace Nav Bar
                    Builder(
                        builder: (context) {
                          final double alertsDelay = 0.45 + (institutions.length * 0.05) + 0.05;
                          return Column(
                            children: [
                              const SizedBox(height: AppDimens.paddingM),
                              FadeInSlide(
                                delay: alertsDelay > 0.8 ? 0.8 : alertsDelay,
                                child: const SyncAlertsCard(),
                              ),
                              AppSpacing.gap100, // Espace pour la nav bar flottante du BAS
                            ],
                          );
                        }
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildAllocationCard(dynamic portfolio) {
    return AppCard(
      backgroundColor: Colors.transparent,
      child: AllocationChart(portfolio: portfolio),
    );
  }

  Widget _buildAssetTypeCard(Map<AssetType, double> allocation, double totalValue) {
    return AppCard(
      backgroundColor: Colors.transparent,
      child: AssetTypeAllocationChart(
        allocationData: allocation,
        totalValue: totalValue,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXS, vertical: AppDimens.paddingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AppIcon(icon: icon, size: AppComponentSizes.iconSmall, color: AppColors.primary, backgroundColor: Colors.transparent),
              AppSpacing.gapHorizontalSmall,
              Text(
                title.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppOpacities.strong),
                ),
              ),
            ],
          ),
          if (onAdd != null)
            AppIconButton(
              icon: Icons.add,
              size: AppComponentSizes.iconXSmall,
              color: AppColors.textPrimary,
              backgroundColor: AppColors.surfaceLight,
              borderColor: AppColors.border,
              borderRadius: 4,
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}