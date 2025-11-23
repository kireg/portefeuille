// lib/core/utils/currency_formatter.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:intl/intl.dart';

/// Un formateur de devises dynamique qui s'adapte
/// à différents codes de devise (EUR, USD, etc.).
class CurrencyFormatter {
  // Un cache pour les formateurs afin d'éviter de les recréer constamment
  static final Map<String, NumberFormat> _formattersCache = {};

  /// Récupère ou crée le formateur pour une devise donnée
  static NumberFormat _getFormatter(String currencyCode) {
    final code = currencyCode.toUpperCase();
    if (_formattersCache.containsKey(code)) {
      return _formattersCache[code]!;
    }

    String locale;
    String symbol;
    int decimalDigits = 2;

    switch (code) {
      case 'EUR':
        locale = 'fr_FR';
        symbol = '€';
        break;
      case 'USD':
        locale = 'en_US';
        symbol = '\$'; // Utilisation du symbole simple
        break;
      case 'GBP':
        locale = 'en_GB';
        symbol = '£';
        break;
      case 'CHF':
        locale = 'de_CH';
        symbol = 'CHF'; // 'fr_CH' utilise 'Fr.'
        break;
      case 'JPY':
        locale = 'ja_JP';
        symbol = '¥';
        decimalDigits = 0; // Le Yen n'a pas de centimes
        break;
      case 'CAD':
        locale = 'en_CA';
        symbol = '\$';
        break;
    // Ajoutez d'autres devises au besoin
      default:
      // Fallback générique
        locale = 'fr_FR';
        symbol = code; // Affiche le code si symbole inconnu
        break;
    }

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );

    _formattersCache[code] = formatter;
    return formatter;
  }

  /// Formate une valeur monétaire en utilisant le code de devise ISO 4217.
  ///
  /// Exemples:
  /// - format(1234.56, 'EUR') -> "1 234,56 €"
  /// - format(1234.56, 'USD') -> "1 234,56 $US"
  static String format(double value, String currencyCode) {
    final formatter = _getFormatter(currencyCode);

    // Fix pour éviter "-0.00" (Negative Zero)
    // Si la valeur absolue est inférieure à la moitié de la plus petite décimale,
    // on force à 0.0 positif.
    final digits = formatter.decimalDigits ?? 2;
    double threshold = 0.5;
    for (int i = 0; i < digits; i++) {
      threshold /= 10;
    }

    if (value.abs() < threshold) {
      value = 0.0;
    }

    return formatter.format(value);
  }

  /// Formate une valeur sans symbole, pour les champs de saisie ou les en-têtes.
  /// Ex: 1234.56 -> "1 234,56"
  static String formatWithoutSymbol(double value, {int decimalDigits = 2}) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: 'fr_FR',
      decimalDigits: decimalDigits,
    );
    return formatter.format(value);
  }

  /// Formate une quantité d'actif (jusqu'à 8 décimales, sans zéros inutiles).
  /// Ex: 10.0 -> "10"
  /// Ex: 0.123456 -> "0,123456"
  static String formatQuantity(double value) {
    final formatter = NumberFormat('#,##0.########', 'fr_FR');
    return formatter.format(value);
  }
}