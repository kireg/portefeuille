// lib/features/01_launch/ui/launch_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../00_app/providers/portfolio_provider.dart';
import '../../02_dashboard/ui/dashboard_screen.dart';
import 'widgets/initial_setup_wizard.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  bool _isCreatingDemo = false;

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
              onPressed: _isCreatingDemo ? null : () async {
                setState(() {
                  _isCreatingDemo = true;
                });

                try {
                  // Mode démo : créer directement et attendre la completion
                  final demo = await portfolioProvider.addDemoPortfolio();
                  
                  // Vérifier que le portefeuille a bien été créé avant de naviguer
                  if (demo != null && mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const DashboardScreen()),
                    );
                  }
                } catch (e) {
                  // Gérer l'erreur si la création échoue
                  debugPrint('Erreur lors de la création du portefeuille de démo: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de la création du portefeuille de démo'),
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isCreatingDemo = false;
                    });
                  }
                }
              },
              child: _isCreatingDemo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Découvrir la version démo'),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: _isCreatingDemo ? null : () async {
                // MODIFIÉ : Lancer l'assistant de configuration
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const InitialSetupWizard(
                      portfolioName: "Mon Portefeuille",
                    ),
                  ),
                );

                // Si le wizard a réussi, aller au dashboard
                if (result == true && context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const DashboardScreen()),
                  );
                }
              },
              child: const Text('Commencer avec un portefeuille vide'),
            ),
          ],
        ),
      ),
    );
  }
}