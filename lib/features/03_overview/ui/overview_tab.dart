// lib/features/03_overview/ui/overview_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';
import 'widgets/portfolio_header.dart';
import 'widgets/institution_list.dart';
import 'widgets/allocation_chart.dart';
import 'widgets/ai_analysis_card.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_institution_screen.dart';

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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PortfolioHeader(portfolio: portfolio),
              const SizedBox(height: 24),
              AllocationChart(portfolio: portfolio),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Structure du Portefeuille',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Ajouter une institution',
                    // --- MODIFIÉ ---
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        // Permet au sheet de s'adapter au clavier
                        isScrollControlled: true,
                        builder: (context) => const AddInstitutionScreen(),
                      );
                    },
                    // --- FIN MODIFICATION ---
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InstitutionList(institutions: portfolio.institutions),
              const SizedBox(height: 24),
              AiAnalysisCard(portfolio: portfolio),
            ],
          ),
        );
      },
    );
  }
}