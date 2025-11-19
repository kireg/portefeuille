import 'dart:io';
import 'package:hive/hive.dart';
import 'package:portefeuille/core/utils/constants.dart';

// Import models for adapters
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/price_history_point.dart';
import 'package:portefeuille/core/data/models/exchange_rate_history.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';

Future<Directory> initTestHive() async {
  final dir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(dir.path);

  // register adapters (matching main.dart)
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
  Hive.registerAdapter(PriceHistoryPointAdapter());
  Hive.registerAdapter(ExchangeRateHistoryAdapter());
  Hive.registerAdapter(SyncStatusAdapter());
  Hive.registerAdapter(SyncLogAdapter());

  // open minimal boxes
  await Hive.openBox(AppConstants.kSettingsBoxName);
  await Hive.openBox(AppConstants.kPortfolioBoxName);
  await Hive.openBox(AppConstants.kTransactionBoxName);
  await Hive.openBox(AppConstants.kAssetMetadataBoxName);
  await Hive.openBox(AppConstants.kPriceHistoryBoxName);
  await Hive.openBox(AppConstants.kExchangeRateHistoryBoxName);
  await Hive.openBox(AppConstants.kSyncLogsBoxName);

  return dir;
}

Future<void> tearDownTestHive(Directory dir) async {
  await Hive.close();
  try {
    await dir.delete(recursive: true);
  } catch (_) {}
}

