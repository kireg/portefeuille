import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/portfolio.dart';
import '../../providers/settings_provider.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';

class AiAnalysisCard extends StatefulWidget {
  final Portfolio portfolio;

  const AiAnalysisCard({super.key, required this.portfolio});

  @override
  State<AiAnalysisCard> createState() => _AiAnalysisCardState();
}

class _AiAnalysisCardState extends State<AiAnalysisCard> {
  bool _isLoading = false;
  String? _analysisResult;

  void _runAnalysis() async {
    setState(() {
      _isLoading = true;
      _analysisResult = null;
    });

    // TODO: Appeler l'API Gemini ici
    // Simuler un appel réseau
    await Future.delayed(const Duration(seconds: 2)); 

    setState(() {
      _isLoading = false;
      _analysisResult = """
### Analyse de votre Portefeuille

**Points Forts:**
* **Bonne diversification:** Vous avez une exposition à la fois aux actions technologiques (AAPL, MSFT) et au luxe (LVMH).
* **Exposition aux crypto-monnaies:** L'investissement dans BTC et ETH pourrait offrir un potentiel de croissance élevé.

**Axes d'amélioration:**
* **Faible exposition internationale hors US/Europe:** Considérez un ETF Marchés Émergents pour une meilleure diversification géographique.
* **Liquidités importantes:** Le solde de liquidités pourrait être investi pour ne pas subir l'inflation.
""";
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyse IA (par Gemini)',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Obtenez des suggestions pour optimiser votre portefeuille. Nécessite le mode "En ligne".',
               style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            if (_analysisResult != null)
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: theme.scaffoldBackgroundColor.withAlpha(40),
                   borderRadius: BorderRadius.circular(8),
                 ),
                // child: MarkdownBody(data: _analysisResult!), // A activer avec le package
                child: Text(_analysisResult!), // Version simple sans Markdown
              ),

            if (_analysisResult == null)
            Center(
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(_isLoading ? 'Analyse en cours...' : 'Lancer l\'analyse'),
                onPressed: settings.isOnlineMode && !_isLoading ? _runAnalysis : null,
                style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                   disabledBackgroundColor: theme.colorScheme.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
