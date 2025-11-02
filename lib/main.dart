import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/portfolio_provider.dart';
import 'providers/settings_provider.dart';

// Screens
import 'screens/dashboard_screen.dart';
import 'screens/welcome_screen.dart';

// Utils
import 'utils/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialiser Hive pour la persistance des données
  // final appDocumentDir = await getApplicationDocumentsDirectory();
  // Hive.init(appDocumentDir.path);
  // await Hive.openBox('portfolio');
  // await Hive.openBox('settings');


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Portefeuille',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: Consumer<PortfolioProvider>(
          builder: (context, portfolioProvider, child) {
            // TODO: Remplacer cette logique par une vraie vérification de portefeuille sauvegardé
            bool portfolioExists = portfolioProvider.portfolio != null;

            if (portfolioExists) {
              return const DashboardScreen();
            } else {
              return const WelcomeScreen();
            }
          },
        ),
      ),
    );
  }
}
