// lib/features/00_app/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/repositories/settings_repository.dart';
import 'package:portefeuille/core/data/abstractions/i_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum UserLevel { novice, expert }

class SettingsProvider extends ChangeNotifier implements ISettings {
  // Clés Hive
  static const String _kIsOnlineMode = 'isOnlineMode';
  static const String _kUserLevel = 'userLevel';
  static const String _kAppColor = 'appColor';
  static const String _kMigrationV1Done = 'migration_v1_done';
  static const String _kMigrationV2Done = 'migration_v2_done';
  static const String _kBaseCurrency = 'baseCurrency';
  static const String _kLastPortfolioId = 'lastPortfolioId';

  // Clés sécurisée
  static const String _kFmpApiKey = 'fmpApiKey';
  static const String _kGeminiApiKey = 'geminiApiKey'; // AJOUT

  // Valeurs par défaut
  static const bool _defaultOnlineMode = false;
  static const int _defaultUserLevelIndex = 0;
  static const int _defaultAppColorValue = 0xFF00bcd4;
  static const String _defaultBaseCurrency = 'EUR';

  late final SettingsRepository _settingsRepo;
  late final FlutterSecureStorage _secureStorage;

  // État
  bool _isOnlineMode = _defaultOnlineMode;
  UserLevel _userLevel = UserLevel.values[_defaultUserLevelIndex];
  Color _appColor = const Color(_defaultAppColorValue);
  String _baseCurrency = _defaultBaseCurrency;
  String? _fmpApiKey;
  String? _geminiApiKey; // AJOUT
  bool _migrationV1Done = false;
  bool _migrationV2Done = false;
  String? _lastPortfolioId;

  // Getters
  bool get isOnlineMode => _isOnlineMode;
  UserLevel get userLevel => _userLevel;
  Color get appColor => _appColor;
  @override
  String get baseCurrency => _baseCurrency;

  @override
  String? get fmpApiKey => _fmpApiKey;
  @override
  bool get hasFmpApiKey => _fmpApiKey != null && _fmpApiKey!.isNotEmpty;

  // Getters Gemini
  String? get geminiApiKey => _geminiApiKey; // AJOUT
  bool get hasGeminiApiKey => _geminiApiKey != null && _geminiApiKey!.isNotEmpty; // AJOUT

  bool get migrationV1Done => _migrationV1Done;
  bool get migrationV2Done => _migrationV2Done;

  /// Implémentation de ISettings - Propriété requise par l'interface
  @override
  int get appColorValue => _appColor.toARGB32();

  SettingsProvider({SettingsRepository? settingsRepository}) {
    _settingsRepo = settingsRepository ?? SettingsRepository();
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    _loadSyncSettings();
    _loadAsyncSettings();
  }

  // Chargement des paramètres simples (HIVE) - Rapide & Synchrone
  void _loadSyncSettings() {
    _isOnlineMode = _settingsRepo.get(_kIsOnlineMode, defaultValue: _defaultOnlineMode);

    final userLevelIndex = _settingsRepo.get(_kUserLevel, defaultValue: _defaultUserLevelIndex);
    _userLevel = UserLevel.values[userLevelIndex.clamp(0, UserLevel.values.length - 1)];

    final appColorValue = _settingsRepo.get(_kAppColor, defaultValue: _defaultAppColorValue);
    _appColor = Color(appColorValue);

    _baseCurrency = _settingsRepo.get(_kBaseCurrency, defaultValue: _defaultBaseCurrency);
    _migrationV1Done = _settingsRepo.get(_kMigrationV1Done, defaultValue: false);
    _migrationV2Done = _settingsRepo.get(_kMigrationV2Done, defaultValue: false);
    _lastPortfolioId = _settingsRepo.get(_kLastPortfolioId);
  }

  // Chargement des paramètres sécurisés (SecureStorage) - Lent & Asynchrone
  Future<void> _loadAsyncSettings() async {
    _fmpApiKey = await _secureStorage.read(key: _kFmpApiKey);
    _geminiApiKey = await _secureStorage.read(key: _kGeminiApiKey); // C'est ICI qu'il faut le mettre
    notifyListeners();
  }

  void setBaseCurrency(String currency) {
    _baseCurrency = currency.toUpperCase();
    _settingsRepo.put(_kBaseCurrency, _baseCurrency);
    notifyListeners();
  }

  Future<void> setMigrationV1Done() async {
    _migrationV1Done = true;
    await _settingsRepo.put(_kMigrationV1Done, true);
  }

  Future<void> setMigrationV2Done() async {
    _migrationV2Done = true;
    await _settingsRepo.put(_kMigrationV2Done, true);
  }

  void toggleOnlineMode(bool value) {
    _isOnlineMode = value;
    _settingsRepo.put(_kIsOnlineMode, value);
    notifyListeners();
  }

  void setUserLevel(UserLevel level) {
    _userLevel = level;
    _settingsRepo.put(_kUserLevel, level.index);
    notifyListeners();
  }

  void setAppColor(Color color) {
    _appColor = color;
    _settingsRepo.put(_kAppColor, color.toARGB32());
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

  // Nouvelle méthode pour Gemini
  Future<void> setGeminiApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      _geminiApiKey = null;
      await _secureStorage.delete(key: _kGeminiApiKey);
    } else {
      _geminiApiKey = key;
      await _secureStorage.write(key: _kGeminiApiKey, value: key);
    }
    notifyListeners();
  }

  /// Recharge tous les paramètres depuis Hive et SecureStorage.
  Future<void> reloadSettings() async {
    debugPrint("🔄 [SettingsProvider] Rechargement des paramètres...");
    _loadSyncSettings();
    await _loadAsyncSettings();
    notifyListeners();
  }

  String? get lastPortfolioId => _lastPortfolioId;

  void setLastPortfolioId(String id) {
    _lastPortfolioId = id;
    _settingsRepo.put(_kLastPortfolioId, id);
  }
}