// lib/features/02_dashboard/ui/dashboard_screen.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import '../../00_app/providers/portfolio_provider.dart';
import '../../00_app/providers/settings_provider.dart';

// Ecrans des onglets
import '../../03_overview/ui/overview_tab.dart';
import '../../05_planner/ui/planner_tab.dart';
import 'package:portefeuille/features/04_journal/ui/journal_tab.dart';
import '../../06_settings/ui/settings_screen.dart';

import '../../07_management/ui/screens/add_transaction_screen.dart';

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

  // NOUVEAU : Gère l'état de la SnackBar
  bool _isSnackBarVisible = false;

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

  /// Construit l'indicateur d'état pour l'AppBar.
  Widget _buildStatusIndicator(
      SettingsProvider settings, PortfolioProvider portfolio) {
    final theme = Theme.of(context);
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

    // MODIFIÉ : Rendre le statut cliquable
    return InkWell(
      onTap: () {
        _showStatusMenu(context, settings, portfolio);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Zone de clic élargie
        child: child,
      ),
    );
  }

  // NOUVEAU : Menu pour le statut (Online/Offline/Synchro)
  void _showStatusMenu(BuildContext context, SettingsProvider settingsProvider,
      PortfolioProvider portfolioProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(settingsProvider.isOnlineMode
                  ? Icons.cloud_off_outlined
                  : Icons.cloud_queue_outlined),
              title: Text(settingsProvider.isOnlineMode
                  ? 'Passer en mode "Hors ligne"'
                  : 'Passer en mode "En ligne"'),
              onTap: () {
                Navigator.of(ctx).pop(); // Ferme le sheet
                _confirmToggleOnline(context, settingsProvider);
              },
            ),
            if (settingsProvider.isOnlineMode)
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Forcer la synchronisation'),
                subtitle: const Text(
                    'Vide le cache et recharge tous les prix (utilise les crédits API).'),
                onTap: () {
                  Navigator.of(ctx).pop(); // Ferme le sheet
                  _confirmForceSync(context, portfolioProvider);
                },
              ),
          ],
        );
      },
    );
  }

  // NOUVEAU : Confirmation pour le changement de mode
  void _confirmToggleOnline(
      BuildContext context, SettingsProvider settingsProvider) {
    final isCurrentlyOnline = settingsProvider.isOnlineMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCurrentlyOnline
            ? 'Passer "Hors ligne" ?'
            : 'Passer "En ligne" ?'),
        content: Text(isCurrentlyOnline
            ? 'L\'application n\'essaiera plus de mettre à jour les prix.'
            : 'L\'application utilisera les données réseau pour mettre à jour les prix.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              settingsProvider.toggleOnlineMode(!isCurrentlyOnline);
              Navigator.of(ctx).pop();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // NOUVEAU : Confirmation pour la synchro forcée
  void _confirmForceSync(
      BuildContext context, PortfolioProvider portfolioProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forcer la synchronisation ?'),
        content: const Text(
            'Cela videra le cache des prix et forcera une nouvelle récupération de toutes les données. Cette action peut consommer vos crédits API (FMP).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style:
            FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () {
              portfolioProvider.forceSynchroniserLesPrix();
              Navigator.of(ctx).pop();
            },
            child: const Text('Forcer'),
          ),
        ],
      ),
    );
  }

  // NOUVEAU : Construit le sélecteur de portefeuille (le titre)
  Widget _buildPortfolioSelector(
      PortfolioProvider provider, Portfolio activePortfolio) {
    return PopupMenuButton<Portfolio>(
      onSelected: (portfolio) {
        provider.setActivePortfolio(portfolio.id);
      },
      itemBuilder: (context) {
        return provider.portfolios.map((portfolio) {
          return PopupMenuItem<Portfolio>(
            value: portfolio,
            child: Row(
              children: [
                if (portfolio.id == activePortfolio.id)
                  const Icon(Icons.check, size: 20)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                Text(portfolio.name),
              ],
            ),
          );
        }).toList();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(activePortfolio.name),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  // NOUVEAU : Gère l'affichage de la SnackBar
  void _handleSyncMessage(BuildContext context, String? message) {
    if (message != null && !_isSnackBarVisible) {
      // Afficher la SnackBar
      setState(() {
        _isSnackBarVisible = true;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      )
          .closed
          .then((_) {
        // S'assurer que le drapeau est remis à false lorsque la SnackBar est fermée
        if (mounted) {
          setState(() {
            _isSnackBarVisible = false;
          });
        }
      });
    } else if (message == null && _isSnackBarVisible) {
      // Cacher la SnackBar si elle est visible et que le message est nul
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {
        _isSnackBarVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // MODIFIÉ : Provider en mode "listen"
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final portfolio = portfolioProvider.activePortfolio;

    // NOUVEAU : Logique de la SnackBar
    // Doit être appelé après la construction du frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleSyncMessage(context, portfolioProvider.syncMessage);
    });

    if (portfolio == null) {
      // ... (code "aucun portefeuille" inchangé)
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
        // --- MODIFICATION : Bouton "+" à gauche ---
        leading: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: 'Ajouter une transaction',
          onPressed: _openAddTransactionModal,
        ),
        // --- FIN MODIFICATION ---

        // --- MODIFICATION : Titre cliquable ---
        title: _buildPortfolioSelector(portfolioProvider, portfolio),
        centerTitle: true,
        // --- FIN MODIFICATION ---

        actions: [
          // MODIFIÉ : Utilise la méthode _buildStatusIndicator qui est maintenant cliquable
          _buildStatusIndicator(settingsProvider, portfolioProvider),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
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

      // --- SUPPRESSION DU FAB ---
      // floatingActionButton: FloatingActionButton(...),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // --- FIN SUPPRESSION ---

      bottomNavigationBar: BottomNavigationBar(
        // --- MODIFICATION : 'centerDocked' n'est plus nécessaire ---
        type: BottomNavigationBarType.fixed,
        // --- FIN MODIFICATION ---
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