// lib/features/03_overview/ui/overview_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';
import 'widgets/portfolio_header.dart';
import 'widgets/allocation_chart.dart';
import 'widgets/asset_type_allocation_chart.dart';
import 'widgets/sync_alerts_card.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_institution_screen.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/03_overview/ui/widgets/account_tile.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_account_screen.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        final portfolio = portfolioProvider.activePortfolio;

        if (portfolio == null) {
          return const Center(child: Text("Aucun portefeuille sélectionné."));
        }

        final institutions = portfolio.institutions;
        final theme = Theme.of(context);

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
                  // Header du portfolio
                  AppTheme.buildStyledCard(
                    context: context,
                    child: PortfolioHeader(portfolio: portfolio),
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
                                child: AllocationChart(portfolio: portfolio),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTheme.buildStyledCard(
                                context: context,
                                child: AssetTypeAllocationChart(
                                  allocationData: portfolio.valueByAssetType,
                                  totalValue: portfolio.totalValue,
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
                              allocationData: portfolio.valueByAssetType,
                              totalValue: portfolio.totalValue,
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
                          ...institutions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final institution = entry.value;
                            return Column(
                              children: [
                                if (index > 0) const SizedBox(height: 12),
                                AppTheme.buildInfoContainer(
                                  context: context,
                                  padding: EdgeInsets.zero,
                                  child: Theme(
                                    data: theme.copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      childrenPadding: EdgeInsets.zero,
                                      title: Text(
                                        institution.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            CurrencyFormatter.format(
                                                institution.totalValue),
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.expand_more),
                                        ],
                                      ),
                                      children: [
                                        Divider(height: 1, indent: 16),
                                        ...institution.accounts.map((account) {
                                          return AccountTile(account: account);
                                        }),
                                        ListTile(
                                          leading: Icon(
                                            Icons.add,
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.6),
                                          ),
                                          title: Text(
                                            'Ajouter un compte',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              builder: (context) =>
                                                  AddAccountScreen(
                                                institutionId: institution.id,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
