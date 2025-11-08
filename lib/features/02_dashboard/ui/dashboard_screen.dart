// lib/features/02_dashboard/ui/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';

// Ecrans des onglets
import '../../03_overview/ui/overview_tab.dart';
import '../../05_planner/ui/planner_tab.dart';
import '../../04_correction/ui/correction_tab.dart';
// Ecran des paramètres
import '../../06_settings/ui/settings_screen.dart';

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
    CorrectionTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    // MODIFIÉ : Utilise activePortfolio au lieu de portfolio
    final portfolio = portfolioProvider.activePortfolio;

    if (portfolio == null) {
      // Sécurité : si aucun portefeuille n'est actif (ex: tous supprimés)
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Aucun portefeuille n'est sélectionné."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Ouvre les paramètres pour en créer/sélectionner un
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => const SettingsScreen(),
                  );
                },
                child: const Text('Gérer les portefeuilles'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // MODIFIÉ : Affiche le nom du portefeuille actif
        title: Text(portfolio.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Permet au BottomSheet de grandir
                builder: (context) => const SettingsScreen(),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
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
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Correction',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}