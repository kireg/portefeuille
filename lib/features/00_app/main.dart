// lib/features/00_app/main.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' hide AssetMetadata;

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
import 'package:portefeuille/core/data/models/repayment_type.dart';

// --- NOUVEAUX IMPORTS ---
import 'package:portefeuille/core/data/models/portfolio_value_history_point.dart';
import 'package:portefeuille/core/data/models/price_history_point.dart';
import 'package:portefeuille/core/data/models/exchange_rate_history.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';
// --- FIN NOUVEAUX IMPORTS ---

// Features
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/services/route_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. ACTIVATION DU MODE IMMERSIF
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
  Hive.registerAdapter(RepaymentTypeAdapter());
  // --- NOUVEAUX ADAPTERS ---
  Hive.registerAdapter(PortfolioValueHistoryPointAdapter());
  Hive.registerAdapter(PriceHistoryPointAdapter());
  Hive.registerAdapter(ExchangeRateHistoryAdapter());
  Hive.registerAdapter(SyncStatusAdapter());
  Hive.registerAdapter(SyncLogAdapter());
  // --- FIN NOUVEAUX ADAPTERS ---

  // 3. Ouvrir les boîtes
  await Hive.openBox<Portfolio>(AppConstants.kPortfolioBoxName);
  await Hive.openBox(AppConstants.kSettingsBoxName);
  await Hive.openBox<Transaction>(AppConstants.kTransactionBoxName);
  await Hive.openBox<AssetMetadata>(AppConstants.kAssetMetadataBoxName);
  // --- NOUVELLES BOXES ---
  await Hive.openBox<PriceHistoryPoint>(AppConstants.kPriceHistoryBoxName);
  await Hive.openBox<ExchangeRateHistory>(
      AppConstants.kExchangeRateHistoryBoxName);
  await Hive.openBox<SyncLog>(AppConstants.kSyncLogsBoxName);
  // --- FIN NOUVELLES BOXES ---

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
            settings: context.read<SettingsProvider>(),  // ✅ SettingsProvider implements ISettings
          ),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, PortfolioProvider>(
          create: (context) => PortfolioProvider(
            repository: repository,
            apiService: context.read<ApiService>(),
          ),

          update: (context, settingsProvider, portfolioProvider) {
            debugPrint(
                "--- ⚡️ ChangeNotifierProxyProvider: UPDATE ⚡️ ---");
            debugPrint(
                "  -> Nouvelle devise injectée: ${settingsProvider.baseCurrency}");

            if (portfolioProvider == null) {
              // Cas de la création initiale
              debugPrint("  -> PortfolioProvider est créé.");
              final newProvider = PortfolioProvider(
                  repository: repository,
                  apiService: context.read<ApiService>());
              newProvider.updateSettings(settingsProvider); // Set initial
              return newProvider;
            }

            // Appel SYSTÉMATIQUE de updateSettings.
            // PortfolioProvider gérera lui-même s'il doit y avoir un recalcul.
            debugPrint(
                "  -> ❗️ Appel de updateSettings (le provider va comparer les devises)");
            portfolioProvider.updateSettings(settingsProvider);
            return portfolioProvider;
          },

        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'Portefeuille',

            // ▼▼▼ MODIFICATION MAJEURE ▼▼▼
            // On force le thème sombre Premium défini dans core/ui
            theme: AppTheme.getTheme(settingsProvider.appColor),
            themeMode: ThemeMode.dark,
            // ▲▲▲ FIN MODIFICATION ▲▲▲

            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', 'FR'),
            ],
            initialRoute: RouteManager.splash,
            onGenerateRoute: RouteManager.onGenerateRoute,
          );
        },
      ),
    );
  }
}