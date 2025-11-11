// lib/features/03_overview/ui/overview_tab.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';
import 'widgets/portfolio_header.dart';
// import 'widgets/institution_list.dart'; // <-- Logique maintenant inlinée
import 'widgets/allocation_chart.dart';
import 'widgets/ai_analysis_card.dart';
import 'widgets/asset_type_allocation_chart.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_institution_screen.dart';

// NOUVEAUX IMPORTS (pour remplacer InstitutionList)
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:portefeuille/features/03_overview/ui/widgets/account_tile.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_account_screen.dart';

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
          // PAS DE PADDING ICI
          slivers: [
            // --- NOUVELLE STRUCTURE DE PADDING ---

            // 1. Contenu statique (Header, Graphiques, Titre)
            // Ce bloc contient tout ce qui n'est PAS la liste lazy-loaded.
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    // 1a. Header
                    PortfolioHeader(portfolio: portfolio),
                    const SizedBox(height: 24),

                    // 1b. Graphiques d'allocation (côte à côte si largeur suffisante)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Si largeur >= 800px, afficher en ligne
                        if (constraints.maxWidth >= 800) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AllocationChart(portfolio: portfolio),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AssetTypeAllocationChart(
                                  allocationData: portfolio.valueByAssetType,
                                  totalValue: portfolio.totalValue,
                                ),
                              ),
                            ],
                          );
                        }
                        // Sinon, afficher en colonne
                        return Column(
                          children: [
                            AllocationChart(portfolio: portfolio),
                            const SizedBox(height: 24),
                            AssetTypeAllocationChart(
                              allocationData: portfolio.valueByAssetType,
                              totalValue: portfolio.totalValue,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // 1d. Titre "Structure du Portefeuille"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Structure du Portefeuille',
                            style: theme.textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline,
                              color: theme.colorScheme.primary),
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
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // 2. Liste des Institutions (Lazy-loaded)
            // On applique seulement un padding horizontal pour que les Cards
            // s'alignent avec le contenu ci-dessus.
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final institution = institutions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ExpansionTile(
                        title: Text(
                          institution.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(institution.totalValue),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [
                          ...institution.accounts.map((account) {
                            return AccountTile(account: account);
                          }).toList(),
                          ListTile(
                            leading: Icon(Icons.add, color: Colors.grey[400]),
                            title: Text(
                              'Ajouter un compte',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => AddAccountScreen(
                                    institutionId: institution.id),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: institutions.length,
                ),
              ),
            ),

            // 3. Analyse IA (avec son propre padding)
            SliverPadding(
              // Padding vertical pour le séparer de la liste
              // Padding horizontal pour l'aligner
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
              sliver: SliverToBoxAdapter(
                child: AiAnalysisCard(portfolio: portfolio),
              ),
            ),
            // --- FIN NOUVELLE STRUCTURE ---
          ],
        );
      },
    );
  }
}
