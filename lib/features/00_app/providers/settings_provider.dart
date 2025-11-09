// lib/features/00_app/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:portefeuille/core/utils/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // NOUVEL IMPORT

enum UserLevel { novice, expert }

class SettingsProvider extends ChangeNotifier {
  // Clés pour la persistance Hive
  static const String _kIsOnlineMode = 'isOnlineMode';
  static const String _kUserLevel = 'userLevel';
  static const String _kAppColor = 'appColor';
  // NOUVELLE CLÉ SÉCURISÉE
  static const String _kFmpApiKey = 'fmpApiKey';

  // Valeurs par défaut
  static const bool _defaultOnlineMode = false;
  static const int _defaultUserLevelIndex = 0; // UserLevel.novice
  static const int _defaultAppColorValue = 0xFF00bcd4; // Cyan par défaut

  late final Box _settingsBox;
  // NOUVEAU : Service de stockage sécurisé
  late final FlutterSecureStorage _secureStorage;

  // Variables d'état local
  bool _isOnlineMode = _defaultOnlineMode;
  UserLevel _userLevel = UserLevel.values[_defaultUserLevelIndex];
  Color _appColor = const Color(_defaultAppColorValue);
  String? _fmpApiKey; // NOUVEAU : Clé API en mémoire

  // Getters publics
  bool get isOnlineMode => _isOnlineMode;
  UserLevel get userLevel => _userLevel;
  Color get appColor => _appColor;
  String? get fmpApiKey => _fmpApiKey; // NOUVEAU
  bool get hasFmpApiKey => _fmpApiKey != null && _fmpApiKey!.isNotEmpty; // NOUVEAU

  SettingsProvider() {
    // 1. Initialiser la boîte
    _settingsBox = Hive.box(AppConstants.kSettingsBoxName);
    // NOUVEAU : Initialiser le stockage sécurisé
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    // 2. Charger les paramètres
    _loadSettings();
  }

  /// Charge les paramètres depuis Hive ET le stockage sécurisé.
  void _loadSettings() async {
    // Charger le mode en ligne
    _isOnlineMode = _settingsBox.get(
      _kIsOnlineMode,
      defaultValue: _defaultOnlineMode,
    );
    // Charger le niveau utilisateur
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
    // Charger la couleur
    final appColorValue = _settingsBox.get(
      _kAppColor,
      defaultValue: _defaultAppColorValue,
    );
    _appColor = Color(appColorValue);

    // NOUVEAU : Charger la clé depuis le stockage sécurisé
    _fmpApiKey = await _secureStorage.read(key: _kFmpApiKey);

    // Note : On notifie les listeners APRES le chargement asynchrone de la clé
    notifyListeners();
  }

  void toggleOnlineMode(bool value) {
    _isOnlineMode = value;
    _settingsBox.put(_kIsOnlineMode, value); // SAUVEGARDE
    notifyListeners();
  }

  void setUserLevel(UserLevel level) {
    _userLevel = level;
    _settingsBox.put(_kUserLevel, level.index); // SAUVEGARDE
    notifyListeners();
  }

  void setAppColor(Color color) {
    _appColor = color;
    _settingsBox.put(_kAppColor, color.value); // SAUVEGARDE
    notifyListeners();
  }

  // --- NOUVELLES MÉTHODES ---

  /// Sauvegarde la clé API FMP de manière sécurisée.
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