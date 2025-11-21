import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';

// Ecrans des onglets
import '../../03_overview/ui/overview_tab.dart';
import '../../05_planner/ui/planner_tab.dart';
import 'package:portefeuille/features/04_journal/ui/views/synthese_view.dart';
import 'package:portefeuille/features/04_journal/ui/views/transactions_view.dart';
import '../../06_settings/ui/settings_screen.dart';
import '../../07_management/ui/screens/add_transaction_screen.dart';

// UI Components
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/components/app_floating_nav_bar.dart'; // Import du nouveau widget
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
    return AppScreen(
      // On met withSafeArea à false pour que le contenu aille jusqu'en bas (sous la nav bar)
      withSafeArea: false,

      // L'AppBar reste gérée par le système standard pour l'instant
      appBar: DashboardAppBar(
        onPressed: _openAddTransactionModal,
      ),

      // Utilisation d'une Stack pour superposer la Nav Bar sur le contenu
      body: Stack(
        children: [
          // 1. Le Contenu (IndexedStack)
          // On lui donne un padding bas pour que le dernier élément ne soit pas caché par la barre
          Padding(
            padding: const EdgeInsets.only(bottom: 0), // Le padding est géré dans les listes (SliverPadding)
            child: IndexedStack(
              index: _selectedIndex,
              children: _widgetOptions,
            ),
          ),

          // 2. La Barre de Navigation Flottante
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