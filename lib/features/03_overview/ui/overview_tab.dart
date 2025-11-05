import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';
import 'widgets/portfolio_header.dart';
import 'widgets/institution_list.dart';
import 'widgets/allocation_chart.dart';
import 'widgets/ai_analysis_card.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final portfolio = portfolioProvider.portfolio;

    if (portfolio == null) {
      return const Center(child: Text("Le portefeuille est vide."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. En-tête avec la valeur totale
          PortfolioHeader(portfolio: portfolio),
          const SizedBox(height: 24),

          // 2. Graphique d'allocation
          AllocationChart(portfolio: portfolio),
          const SizedBox(height: 24),

          // 3. Structure du portefeuille
          Text(
            'Structure du Portefeuille',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          InstitutionList(institutions: portfolio.institutions),
          const SizedBox(height: 24),

          // 4. Analyse IA
          AiAnalysisCard(portfolio: portfolio),
        ],
      ),
    );
  }
}
