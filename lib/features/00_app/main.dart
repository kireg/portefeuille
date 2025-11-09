// lib/features/00_app/main.dart
// REMPLACEZ LE FICHIER COMPLET

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
import 'package:portefeuille/core/data/services/api_service.dart';

import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';

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
  Hive.registerAdapter(SavingsPlanAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(AssetTypeAdapter());
  Hive.registerAdapter(AssetMetadataAdapter());

  // 3. Ouvrir les boîtes
  await Hive.openBox<Portfolio>(AppConstants.kPortfolioBoxName);
  await Hive.openBox(AppConstants.kSettingsBoxName);

  // NOUVEAU : Ouvrir la boîte des transactions
  await Hive.openBox<Transaction>(AppConstants.kTransactionBoxName);
  
  // NOUVEAU : Ouvrir la boîte des métadonnées d'actifs
  await Hive.openBox<AssetMetadata>(AppConstants.kAssetMetadataBoxName);

  // 4. Instancier le Repository
  final portfolioRepository = PortfolioRepository();
  runApp(MyApp(repository: portfolioRepository));
}

class MyApp extends StatelessWidget {
  final PortfolioRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    // Le MultiProvider reste inchangé
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        Provider<ApiService>(
          create: (context) => ApiService(
            settingsProvider: context.read<SettingsProvider>(),
          ),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, PortfolioProvider>(
          create: (context) => PortfolioProvider(
            repository: repository,
            apiService: context.read<ApiService>(),
          ),
          update: (context, settingsProvider, portfolioProvider) {
            if (portfolioProvider == null) {
              return PortfolioProvider(
                  repository: repository,
                  apiService: context.read<ApiService>());
            }
            portfolioProvider.updateSettings(settingsProvider);
            return portfolioProvider;
          },
        ),
      ],
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
  }
}