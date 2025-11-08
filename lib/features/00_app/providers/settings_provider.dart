// lib/features/00_app/providers/settings_provider.dart

import 'package:flutter/material.dart';

enum UserLevel { novice, expert }

class SettingsProvider extends ChangeNotifier {
  bool _isOnlineMode = false;
  UserLevel _userLevel = UserLevel.novice;

  // NOUVEAU : Couleur de l'application (initialisée à la couleur cyan par défaut)
  Color _appColor = const Color(0xFF00bcd4);

  bool get isOnlineMode => _isOnlineMode;
  UserLevel get userLevel => _userLevel;
  Color get appColor => _appColor; // NOUVEAU : Getter

  // TODO: Charger les paramètres depuis SharedPreferences

  void toggleOnlineMode(bool value) {
    _isOnlineMode = value;
    // TODO: Sauvegarder dans SharedPreferences
    notifyListeners();
  }

  void setUserLevel(UserLevel level) {
    _userLevel = level;
    // TODO: Sauvegarder dans SharedPreferences
    notifyListeners();
  }

  // NOUVEAU : Setter pour la couleur
  void setAppColor(Color color) {
    _appColor = color;
    // TODO: Sauvegarder dans SharedPreferences
    notifyListeners();
  }
}