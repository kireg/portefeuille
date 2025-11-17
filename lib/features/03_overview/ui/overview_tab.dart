// lib/features/03_overview/ui/overview_tab.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// NOUVEAUX IMPORTS
import '../../00_app/providers/portfolio_provider.dart';
// FIN NOUVEAUX IMPORTS
import 'widgets/portfolio_header.dart';
import 'widgets/allocation_chart.dart';
import 'widgets/asset_type_allocation_chart.dart';
import 'widgets/sync_alerts_card.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_institution_screen.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';
import 'package:portefeuille/features/03_overview/ui/widgets/institution_tile.dart';
// <-- NOUVEL IMPORT

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Note : On n'utilise plus baseCurrency d'ici, on le lit du provider

    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        final portfolio = portfolioProvider.activePortfolio;

        if (portfolio == null) {
          return const Center(child: Text("Aucun portefeuille sélectionné."));
        }

        final institutions = portfolio.institutions;
        final theme = Theme.of(context);

        // La devise de base vient maintenant du provider (elle est synchronisée)

        return CustomScrollView(
          slivers: [
            // En-tête avec titre
            SliverToBoxAdapter(
              child: AppTheme.buildScreenTitle(
                context: context,
                title: 'Vue d\'ensemble',
                centered: true,
              ),
            ),

            // Contenu principal
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header du portfolio (ne prend plus de paramètre)
                  AppTheme.buildStyledCard(
                    context: context,
                    child: const PortfolioHeader(), // <-- MODIFIÉ
                  ),
                  const SizedBox(height: 12),

                  // Graphiques d'allocation
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTheme.buildStyledCard(
                                context: context,
                                // TODO: AllocationChart doit aussi être mis à jour
                                child: AllocationChart(portfolio: portfolio),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTheme.buildStyledCard(
                                context: context,
                                child: AssetTypeAllocationChart(
                                  // ▼▼▼ MODIFIÉ ▼▼▼
                                  // Utilise le getter du provider (données converties)
                                  allocationData: portfolioProvider
                                      .aggregatedValueByAssetType,
                                  totalValue: portfolioProvider
                                      .activePortfolioTotalValue,
                                  // ▲▲▲ FIN MODIFICATION ▲▲▲
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          AppTheme.buildStyledCard(
                            context: context,
                            child: AllocationChart(portfolio: portfolio),
                          ),
                          const SizedBox(height: 12),
                          AppTheme.buildStyledCard(
                            context: context,
                            child: AssetTypeAllocationChart(
                              // ▼▼▼ MODIFIÉ ▼▼▼
                              allocationData: portfolioProvider
                                  .aggregatedValueByAssetType,
                              totalValue: portfolioProvider
                                  .activePortfolioTotalValue,
                              // ▲▲▲ FIN MODIFICATION ▲▲▲
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Section Institutions
                  AppTheme.buildStyledCard(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTheme.buildSectionHeader(
                          context: context,
                          icon: Icons.account_balance,
                          title: 'Structure du Portefeuille',
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            tooltip: 'Ajouter une institution',
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) =>
                                const AddInstitutionScreen(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Liste des institutions
                        if (institutions.isEmpty)
                          AppTheme.buildInfoContainer(
                            context: context,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Aucune institution. Ajoutez-en une pour commencer.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          )
                        else
                        // ▼▼▼ MODIFIÉ : Utilisation du nouveau widget InstitutionTile ▼▼▼
                          ...institutions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final institution = entry.value;
                            return Column(
                              children: [
                                if (index > 0) const SizedBox(height: 12),
                                // On passe juste le modèle Institution
                                InstitutionTile(institution: institution),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Alertes de synchronisation (en bas)
                  AppTheme.buildStyledCard(
                    context: context,
                    child: const SyncAlertsCard(),
                  ),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}