// lib/features/02_dashboard/ui/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';
// NOUVEL IMPORT
import '../../00_app/providers/settings_provider.dart';

// Ecrans des onglets
import '../../03_overview/ui/overview_tab.dart';
import '../../05_planner/ui/planner_tab.dart';
import '../../04_correction/ui/correction_tab.dart';
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

  // --- NOUVELLE FONCTION (WIDGET D'ÉTAT) ---
  /// Construit l'indicateur d'état pour l'AppBar.
  Widget _buildStatusIndicator(
      SettingsProvider settings, PortfolioProvider portfolio) {
    final theme = Theme.of(context);
    // Style pour le texte dans l'AppBar (clair)
    final textStyle = theme.appBarTheme.titleTextStyle?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ) ??
        const TextStyle(color: Colors.white, fontSize: 12);

    Widget child;

    if (portfolio.isSyncing) {
      child = Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text("Synchro...", style: textStyle),
        ],
      );
    } else if (settings.isOnlineMode) {
      child = Row(
        children: [
          Icon(Icons.cloud_queue_outlined,
              size: 16, color: textStyle.color),
          const SizedBox(width: 8),
          Text("En ligne", style: textStyle),
        ],
      );
    } else {
      child = Row(
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 16, color: textStyle.color?.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text("Hors ligne", style: textStyle),
        ],
      );
    }

    // Ajoute un padding pour ne pas coller l'icône des paramètres
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: child,
    );
  }
  // --- FIN NOUVELLE FONCTION ---

  @override
  Widget build(BuildContext context) {
    // --- MODIFIÉ ---
    // Nous avons besoin des deux providers
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    // --- FIN MODIFICATION ---

    final portfolio = portfolioProvider.activePortfolio;

    if (portfolio == null) {
      // (Partie "Aucun portefeuille" inchangée)
      return Scaffold(
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
      appBar: AppBar(
        title: Text(portfolio.name),
        // --- MODIFIÉ (Actions de l'AppBar) ---
        actions: [
          // 1. Notre nouvel indicateur de statut
          _buildStatusIndicator(settingsProvider, portfolioProvider),

          // 2. Le bouton de paramètres existant
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
        // --- FIN MODIFICATION ---
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