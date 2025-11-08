// lib/features/01_launch/ui/launch_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';
import '../../02_dashboard/ui/dashboard_screen.dart';

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolioProvider =
    Provider.of<PortfolioProvider>(context, listen: false);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenue dans Portefeuille',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
                // MODIFIÉ : Appel de la nouvelle méthode
                portfolioProvider.addDemoPortfolio();

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const DashboardScreen()),
                );
              },
              child: const Text('Découvrir la version démo'),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
                // MODIFIÉ : Appel de la nouvelle méthode
                // (Pour l'instant, nom par défaut. On pourra ajouter un dialogue plus tard)
                portfolioProvider.addNewPortfolio("Mon Portefeuille");

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const DashboardScreen()),
                );
              },
              child: const Text('Commencer avec un portefeuille vide'),
            ),
          ],
        ),
      ),
    );
  }
}