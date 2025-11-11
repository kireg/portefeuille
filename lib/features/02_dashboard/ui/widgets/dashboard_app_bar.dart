// lib/features/02_dashboard/ui/widgets/dashboard_app_bar.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/06_settings/ui/settings_screen.dart';
import 'package:provider/provider.dart';

class DashboardAppBar extends StatefulWidget implements PreferredSizeWidget {
  // NOUVEAU : Ajout du paramètre (Correction Erreurs 4, 5, 6)
  final VoidCallback onPressed;

  const DashboardAppBar({
    super.key,
    required this.onPressed,
  });

  @override
  State<DashboardAppBar> createState() => _DashboardAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DashboardAppBarState extends State<DashboardAppBar> {
  // Gère l'état de la SnackBar
  bool _isSnackBarVisible = false;

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

    // Rendre le statut cliquable
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

  // Menu pour le statut (Online/Offline/Synchro)
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

  // Confirmation pour le changement de mode
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

  // Confirmation pour la synchro forcée
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
              // MODIFIÉ : Utilise context.read pour appeler la fonction
              context.read<PortfolioProvider>().forceSynchroniserLesPrix();
              Navigator.of(ctx).pop();
            },
            child: const Text('Forcer'),
          ),
        ],
      ),
    );
  }

  // Construit le sélecteur de portefeuille (le titre)
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
          Flexible(
            child: Text(
              activePortfolio.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  // Gère l'affichage de la SnackBar de notification
  void _handleSyncMessage(BuildContext context, PortfolioProvider provider) {
    final message = provider.syncMessage;
    if (message != null && !_isSnackBarVisible) {
      // Afficher la SnackBar
      setState(() {
        _isSnackBarVisible = true;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4), // <-- DURÉE MODIFIÉE
          showCloseIcon: true,
        ),
      )
          .closed
          .then((_) {
        // S'assurer que le drapeau est remis à false
        if (mounted) {
          provider.clearSyncMessage();
          setState(() {
            _isSnackBarVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écoute les changements pour la SnackBar et le titre
    final portfolioProvider = context.watch<PortfolioProvider>();
    // Ne 'listen' pas, car le clic déclenche la propre reconstruction du menu
    final settingsProvider = context.read<SettingsProvider>();
    final portfolio = portfolioProvider.activePortfolio;

    // Logique de la SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleSyncMessage(context, portfolioProvider);
    });

    if (portfolio == null) {
      // AppBar pour l'état sans portefeuille
      return AppBar(
        title: const Text('Portefeuille'),
        actions: [
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
      );
    }

    // AppBar principale
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: 'Ajouter une transaction',
        // MODIFIÉ : Utilise le paramètre (Correction Erreurs 4, 5, 6)
        onPressed: widget.onPressed,
      ),
      title: _buildPortfolioSelector(portfolioProvider, portfolio),
      centerTitle: true,
      actions: [
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
    );
  }
}