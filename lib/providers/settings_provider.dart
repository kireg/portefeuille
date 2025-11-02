import 'package:flutter/material.dart';

enum UserLevel { Novice, Expert }

class SettingsProvider extends ChangeNotifier {
  bool _isOnlineMode = false;
  UserLevel _userLevel = UserLevel.Novice;

  bool get isOnlineMode => _isOnlineMode;
  UserLevel get userLevel => _userLevel;

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
}
