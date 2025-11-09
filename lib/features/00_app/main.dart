// lib/features/00_app/main.dart

import 'package:flutter/foundation.dart';
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
// --- NOUVEL IMPORT ---
import 'package:portefeuille/core/data/services/api_service.dart';
// --- FIN NOUVEL IMPORT ---
// Features
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

import 'package:portefeuille/core/ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialiser Hive
  await Hive.initFlutter();
  if (kDebugMode) {
    // TEMPORAIRE : Suppression pour tester le nouveau modèle avec données démo
    await Hive.deleteFromDisk();
  }

  // 2. Enregistrer les Adapters (INCLUANT CELUI DE VOTRE NOUVELLE VERSION)
  Hive.registerAdapter(PortfolioAdapter());
  Hive.registerAdapter(InstitutionAdapter());
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(AssetAdapter());
  Hive.registerAdapter(AccountTypeAdapter());
  Hive.registerAdapter(SavingsPlanAdapter()); // CONSERVÉ [cite: 182]

  // 3. Ouvrir les boîtes
  await Hive.openBox<Portfolio>(AppConstants.kPortfolioBoxName);
  await Hive.openBox(AppConstants.kSettingsBoxName);

  // 4. Instancier le Repository
  final portfolioRepository = PortfolioRepository();
  runApp(MyApp(repository: portfolioRepository));
}

class MyApp extends StatelessWidget {
  final PortfolioRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    // --- MODIFICATION MAJEURE (MultiProvider) ---
    return MultiProvider(
      providers: [
        // 1. SettingsProvider (indépendant)
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // 2. ApiService (dépend de SettingsProvider)
        Provider<ApiService>(
          create: (context) => ApiService(
            settingsProvider: context.read<SettingsProvider>(),
          ),
        ),

        // 3. PortfolioProvider (dépend de ApiService et SettingsProvider)
        ChangeNotifierProxyProvider<SettingsProvider, PortfolioProvider>(
          // 'create' est appelé 1 fois
          create: (context) => PortfolioProvider(
            repository: repository,
            apiService: context.read<ApiService>(),
          ),
          // 'update' est appelé à chaque fois que SettingsProvider notifie
          update: (context, settingsProvider, portfolioProvider) {
            if (portfolioProvider == null) {
              return PortfolioProvider(
                  repository: repository,
                  apiService: context.read<ApiService>());
            }
            // On notifie le PortfolioProvider des changements de settings
            portfolioProvider.updateSettings(settingsProvider);
            return portfolioProvider;
          },
        ),
      ],
      // Le Consumer<SettingsProvider> pour le Thème est inchangé
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'Portefeuille',
            theme: AppTheme.getTheme(settingsProvider.appColor),
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
    // --- FIN MODIFICATION ---
  }
}