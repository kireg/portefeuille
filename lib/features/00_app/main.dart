import 'package:flutter/foundation.dart'; // Importer kDebugMode
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Core
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';
import 'package:portefeuille/core/utils/constants.dart';
// Features
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

// MODIFICATION: Importer le nouveau SplashScreen
import 'package:portefeuille/core/ui/splash_screen.dart';
// Ces imports ne sont plus nécessaires ici, mais dans le SplashScreen
// import 'package:portefeuille/features/02_dashboard/ui/dashboard_screen.dart';
// import 'package:portefeuille/features/01_launch/ui/launch_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialiser Hive
  await Hive.initFlutter();

  if (kDebugMode) {
    await Hive.deleteFromDisk();
  }

  // 2. Enregistrer les Adapters
  Hive.registerAdapter(PortfolioAdapter());
  Hive.registerAdapter(InstitutionAdapter());
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(AssetAdapter());
  Hive.registerAdapter(AccountTypeAdapter());

  // 3. Ouvrir la boîte de stockage principale
  await Hive.openBox<Portfolio>(AppConstants.kPortfolioBoxName);

  // 4. Instancier le Repository (MAINTENANT que la box est ouverte)
  final portfolioRepository = PortfolioRepository();

  runApp(MyApp(repository: portfolioRepository));
}

class MyApp extends StatelessWidget {
  final PortfolioRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // On injecte le repository instancié dans le Provider
        ChangeNotifierProvider(
          create: (_) => PortfolioProvider(repository: repository),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      // MODIFICATION: Le Consumer est retiré d'ici.
      // Le MaterialApp est l'enfant direct du MultiProvider
      // afin que le SplashScreen puisse accéder aux providers.
      child: MaterialApp(
        title: 'Portefeuille',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        // MODIFICATION: Le SplashScreen est maintenant l'écran d'accueil.
        // Il contient la logique pour naviguer vers LaunchScreen ou DashboardScreen.
        home: const SplashScreen(),
      ),
    );
  }
}