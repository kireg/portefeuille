// lib/features/02_dashboard/ui/dashboard_screen.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';
// import '../../00_app/providers/settings_provider.dart'; // Géré par l'AppBar

// Ecrans des onglets
import '../../03_overview/ui/overview_tab.dart';
import '../../05_planner/ui/planner_tab.dart';
import 'package:portefeuille/features/04_journal/ui/journal_tab.dart';
import '../../06_settings/ui/settings_screen.dart';

import '../../07_management/ui/screens/add_transaction_screen.dart';
// NOUVEL IMPORT
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
    JournalTab(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permet au sheet de prendre tout l'écran
      builder: (context) => const AddTransactionScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Le provider est juste lu ici pour vérifier si un portefeuille existe
    final portfolioProvider = context.read<PortfolioProvider>();
    final portfolio = portfolioProvider.activePortfolio;

    if (portfolio == null) {
      // ... (code "aucun portefeuille" inchangé)
      return Scaffold(
        // MODIFIÉ : Utilise la nouvelle AppBar même s'il n'y a pas de portefeuille
        appBar: DashboardAppBar(
          onPressed: _openAddTransactionModal,
        ),
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

    return Scaffold(
      // MODIFIÉ : Utilise la nouvelle AppBar personnalisée
      appBar: DashboardAppBar(
        onPressed: _openAddTransactionModal,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),

      // --- FAB Supprimé ---

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Vue d\'ensemble',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Planificateur',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Journal',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}