// lib/features/00_app/main.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
// Core
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';
import 'package:portefeuille/core/utils/constants.dart';
// Features
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

import 'package:portefeuille/core/ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialiser Hive
  await Hive.initFlutter();

  // 2. Enregistrer les Adapters
  Hive.registerAdapter(PortfolioAdapter());
  Hive.registerAdapter(InstitutionAdapter());
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(AssetAdapter());
  Hive.registerAdapter(AccountTypeAdapter());
  Hive.registerAdapter(SavingsPlanAdapter()); // Adapter pour les plans d'épargne

  // 3. Ouvrir les boîtes
  await Hive.openBox<Portfolio>(AppConstants.kPortfolioBoxName);
  await Hive.openBox(AppConstants.kSettingsBoxName); // MODIFIÉ : Ajout de la boîte des settings

  // 4. Instancier le Repository
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
        ChangeNotifierProvider(
          create: (_) => PortfolioProvider(repository: repository),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      // MODIFIÉ : Le MaterialApp est maintenant dans un Consumer
      // pour lire le SettingsProvider
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'Portefeuille',
            // MODIFIÉ : Utilise la méthode getTheme avec la couleur du provider
            theme: AppTheme.getTheme(settingsProvider.appColor),
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}