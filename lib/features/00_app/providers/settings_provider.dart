// lib/features/00_app/providers/settings_provider.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:portefeuille/core/utils/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum UserLevel { novice, expert }

class SettingsProvider extends ChangeNotifier {
  // Clés Hive
  static const String _kIsOnlineMode = 'isOnlineMode';
  static const String _kUserLevel = 'userLevel';
  static const String _kAppColor = 'appColor';
  static const String _kMigrationV1Done = 'migration_v1_done';
  static const String _kBaseCurrency = 'baseCurrency';
  static const String _kMigrationV2Done = 'migration_v2_done'; // <-- NOUVEAU

  // Clé sécurisée
  static const String _kFmpApiKey = 'fmpApiKey';
  // Valeurs par défaut
  static const bool _defaultOnlineMode = false;
  static const int _defaultUserLevelIndex = 0;
  static const int _defaultAppColorValue = 0xFF00bcd4;
  static const String _defaultBaseCurrency = 'EUR';

  late final Box _settingsBox;
  late final FlutterSecureStorage _secureStorage;
  // Variables d'état
  bool _isOnlineMode = _defaultOnlineMode;
  UserLevel _userLevel = UserLevel.values[_defaultUserLevelIndex];
  Color _appColor = const Color(_defaultAppColorValue);
  String _baseCurrency = _defaultBaseCurrency;
  String? _fmpApiKey;
  bool _migrationV1Done = false;
  bool _migrationV2Done = false; // <-- NOUVEAU

  // Getters publics
  bool get isOnlineMode => _isOnlineMode;
  UserLevel get userLevel => _userLevel;
  Color get appColor => _appColor;
  String get baseCurrency => _baseCurrency;
  String? get fmpApiKey => _fmpApiKey;
  bool get hasFmpApiKey => _fmpApiKey != null && _fmpApiKey!.isNotEmpty;
  bool get migrationV1Done => _migrationV1Done;
  bool get migrationV2Done => _migrationV2Done; // <-- NOUVEAU

  SettingsProvider() {
    _settingsBox = Hive.box(AppConstants.kSettingsBoxName);
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    _loadSyncSettings();
    _loadAsyncSettings();
  }

  /// Charge les paramètres synchrones depuis Hive.
  void _loadSyncSettings() {
    _isOnlineMode = _settingsBox.get(
      _kIsOnlineMode,
      defaultValue: _defaultOnlineMode,
    );
    final userLevelIndex = _settingsBox.get(
      _kUserLevel,
      defaultValue: _defaultUserLevelIndex,
    );
    final allLevels = UserLevel.values;
    if (userLevelIndex >= 0 && userLevelIndex < allLevels.length) {
      _userLevel = allLevels[userLevelIndex];
    } else {
      _userLevel = allLevels[_defaultUserLevelIndex];
    }
    final appColorValue = _settingsBox.get(
      _kAppColor,
      defaultValue: _defaultAppColorValue,
    );
    _appColor = Color(appColorValue);

    _migrationV1Done = _settingsBox.get(_kMigrationV1Done, defaultValue: false);
    _migrationV2Done = _settingsBox.get(_kMigrationV2Done, defaultValue: false); // <-- NOUVEAU
    _baseCurrency =
        _settingsBox.get(_kBaseCurrency, defaultValue: _defaultBaseCurrency);
  }

  /// Charge les paramètres asynchrones (clé API).
  Future<void> _loadAsyncSettings() async {
    _fmpApiKey = await _secureStorage.read(key: _kFmpApiKey);
    notifyListeners();
  }

  void setBaseCurrency(String currency) {
    _baseCurrency = currency.toUpperCase();
    _settingsBox.put(_kBaseCurrency, _baseCurrency);
    notifyListeners();
  }

  Future<void> setMigrationV1Done() async {
    _migrationV1Done = true;
    await _settingsBox.put(_kMigrationV1Done, true);
  }

  // NOUVEAU : Méthode pour définir le drapeau de migration V2
  Future<void> setMigrationV2Done() async {
    _migrationV2Done = true;
    await _settingsBox.put(_kMigrationV2Done, true);
  }

  void toggleOnlineMode(bool value) {
    _isOnlineMode = value;
    _settingsBox.put(_kIsOnlineMode, value);
    notifyListeners();
  }

  void setUserLevel(UserLevel level) {
    _userLevel = level;
    _settingsBox.put(_kUserLevel, level.index);
    notifyListeners();
  }

  void setAppColor(Color color) {
    _appColor = color;
    _settingsBox.put(_kAppColor, color.value);
    notifyListeners();
  }

  Future<void> setFmpApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      _fmpApiKey = null;
      await _secureStorage.delete(key: _kFmpApiKey);
    } else {
      _fmpApiKey = key;
      await _secureStorage.write(key: _kFmpApiKey, value: key);
    }
    notifyListeners();
  }
}