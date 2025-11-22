import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';

// Ecrans des onglets
import '../../03_overview/ui/overview_tab.dart';
import '../../05_planner/ui/planner_tab.dart';
import '../../05_planner/ui/crowdfunding_tracking_tab.dart'; // NOUVEL ONGLET
import 'package:portefeuille/features/04_journal/ui/views/synthese_view.dart';
import 'package:portefeuille/features/04_journal/ui/views/transactions_view.dart';
import '../../06_settings/ui/settings_screen.dart';
import '../../07_management/ui/screens/add_transaction_screen.dart';

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

  static const List<Widget> _widgetOptions = <Widget>[
    OverviewTab(),
    PlannerTab(),
    CrowdfundingTrackingTab(), // NOUVEL ONGLET
    SyntheseView(),
    TransactionsView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddTransactionScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = context.read<PortfolioProvider>();
    final portfolio = portfolioProvider.activePortfolio;

    // Cas "Aucun portefeuille"
    if (portfolio == null) {
      return AppScreen(
        // Ici on garde l'AppBar classique car l'écran est vide
        appBar: DashboardAppBar(onPressed: _openAddTransactionModal),
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
            index: _selectedIndex,
            children: _widgetOptions,
          ),

          // 2. La Barre Supérieure (Flottante)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DashboardAppBar(
              onPressed: _openAddTransactionModal,
            ),
          ),

          // 3. La Barre de Navigation (Flottante en bas)
          AppFloatingNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              AppNavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard,
                label: 'Vue',
              ),
              AppNavItem(
                icon: Icons.calendar_today_outlined,
                selectedIcon: Icons.calendar_today,
                label: 'Plan',
              ),
              AppNavItem(
                icon: Icons.rocket_launch_outlined,
                selectedIcon: Icons.rocket_launch,
                label: 'Crowd',
              ),
              AppNavItem(
                icon: Icons.pie_chart_outline,
                selectedIcon: Icons.pie_chart,
                label: 'Synthèse',
              ),
              AppNavItem(
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: 'Journal',
              ),
            ],
          ),
        ],
      ),
    );
  }
}