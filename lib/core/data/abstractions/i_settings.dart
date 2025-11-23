// lib/core/data/abstractions/i_settings.dart
//
// Interface abstraite pour accéder aux paramètres de l'application.
// Permet au Core de rester indépendant du layer Features.
//
// Migration Phase 1 - Étape 1.3: Abstraction des Settings

/// Interface pour accéder aux paramètres d'application
abstract class ISettings {
  /// La clé API FMP (Financial Modeling Prep) si configurée
  String? get fmpApiKey;

  /// Indique si une clé API FMP est disponible
  bool get hasFmpApiKey;

  /// La devise de base de l'utilisateur (ex: "EUR", "USD")
  String get baseCurrency;

  /// La couleur thème de l'application
  /// Retourne une valeur au format 0xAARRGGBB
  int get appColorValue;

  /// L'ordre de priorité des services de données (ex: ["FMP", "Yahoo", "Google"])
  List<String> get serviceOrder;
}

