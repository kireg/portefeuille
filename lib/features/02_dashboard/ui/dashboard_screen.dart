import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';

// Ecrans des onglets
import '../../03_overview/ui/overview_tab.dart';
import '../../05_planner/ui/planner_tab.dart';
import '../../05_planner/ui/crowdfunding_tracking_tab.dart'; // NOUVEL ONGLET
import 'package:portefeuille/features/04_journal/ui/views/synthese_view.dart';
import 'package:portefeuille/features/04_journal/ui/views/transactions_view.dart';
import '../../06_settings/ui/settings_screen.dart';

// UI Components
import 'package:portefeuille/core/ui/theme/app_colors.dart'; // Pour le fond par défaut
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/components/app_floating_nav_bar.dart';
import 'widgets/dashboard_app_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = context.select<PortfolioProvider, Portfolio?>((p) => p.activePortfolio);

    // Cas "Aucun portefeuille"
    if (portfolio == null) {
      return AppScreen(
        // Ici on garde l'AppBar classique car l'écran est vide
        appBar: const DashboardAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Aucun portefeuille n'est sélectionné."),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => const SettingsScreen(),
                    );
                  },
                  child: const Text('Gérer les portefeuilles')),
            ],
          ),
        ),
      );
    }

    // Construire les onglets dynamiquement
    final List<Widget> tabs = [
      const OverviewTab(),
      const PlannerTab(),
      const CrowdfundingTrackingTab(),
      const SyntheseView(),
    ];

    final List<AppNavItem> navItems = [
      const AppNavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Vue',
      ),
      const AppNavItem(
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        label: 'Plan',
      ),
      const AppNavItem(
        icon: Icons.rocket_launch_outlined,
        selectedIcon: Icons.rocket_launch,
        label: 'Crowd',
      ),
      const AppNavItem(
        icon: Icons.pie_chart_outline,
        selectedIcon: Icons.pie_chart,
        label: 'Synthèse',
      ),
    ];

    tabs.add(const TransactionsView());
    navItems.add(const AppNavItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Journal',
    ));

    // Sécurité pour l'index
    final safeIndex = _selectedIndex >= tabs.length ? 0 : _selectedIndex;

    // Dashboard complet
    return Scaffold(
      // On utilise un Scaffold simple ici.
      // La couleur de fond assure qu'il n'y a pas de flash blanc,
      // mais c'est l'AppScreen à l'intérieur des onglets (OverviewTab) qui fera le vrai gradient.
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false, // Évite que le clavier casse la layout

      body: Stack(
        children: [
          // 1. Le Contenu (Les Onglets)
          // CORRECTION : Plus de padding TOP ici. L'onglet prend tout l'écran.
          IndexedStack(
            index: safeIndex,
            children: tabs,
          ),

          // 2. La Barre Supérieure (Flottante)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DashboardAppBar(),
          ),

          // 3. La Barre de Navigation (Flottante en bas)
          AppFloatingNavBar(
            currentIndex: safeIndex,
            onTap: _onItemTapped,
            items: navItems,
          ),
        ],
      ),
    );
  }
}