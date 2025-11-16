// lib/core/utils/isin_validator.dart

/// Utilitaire de validation des codes ISIN (International Securities Identification Number)
///
/// Format ISIN : 12 caractères alphanumériques
/// - 2 lettres : code pays (ISO 3166-1 alpha-2)
/// - 9 alphanumériques : identifiant national
/// - 1 chiffre : clé de contrôle (checksum)
///
/// Exemple : US0378331005 (Apple Inc.)
class IsinValidator {
  /// Vérifie si une chaîne correspond au format ISIN de base (longueur + structure)
  ///
  /// Validation stricte : 2 lettres majuscules + 10 alphanumériques
  ///
  /// Exemples :
  /// - US0378331005 → true
  /// - FR0000120073 → true
  /// - AAPL → false (trop court)
  /// - 123456789012 → false (ne commence pas par des lettres)
  static bool isValidIsinFormat(String value) {
    if (value.length != 12) return false;

    // Vérifier les 2 premiers caractères sont des lettres majuscules
    final countryCode = value.substring(0, 2);
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
      return false;
    }

    // Vérifier que les 10 caractères suivants sont alphanumériques
    final securityId = value.substring(2);
    if (!RegExp(r'^[A-Z0-9]{10}$').hasMatch(securityId)) {
      return false;
    }

    return true;
  }

  /// Vérifie si une chaîne correspond au format ISIN avec validation du checksum (algorithme Luhn modifié)
  ///
  /// Cette validation est plus stricte et vérifie que le dernier chiffre
  /// est correct selon l'algorithme de Luhn modifié pour les ISIN.
  ///
  /// Note : Cette validation est optionnelle car certains systèmes
  /// peuvent avoir des ISIN avec checksums incorrects dans leurs bases de données.
  static bool isValidIsinWithChecksum(String isin) {
    if (!isValidIsinFormat(isin)) return false;

    // Convertir les lettres en chiffres (A=10, B=11, ..., Z=35)
    String digits = '';
    for (int i = 0; i < isin.length; i++) {
      final char = isin[i];
      if (RegExp(r'[A-Z]').hasMatch(char)) {
        // A=10, B=11, ..., Z=35
        digits += (char.codeUnitAt(0) - 'A'.codeUnitAt(0) + 10).toString();
      } else {
        digits += char;
      }
    }

    // Appliquer l'algorithme de Luhn (de droite à gauche)
    int sum = 0;
    bool alternate = false;

    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return (sum % 10) == 0;
  }

  /// Détecte si une recherche utilisateur ressemble à un ISIN
  ///
  /// Critères moins stricts pour détecter une tentative de recherche par ISIN :
  /// - Commence par 2 lettres
  /// - Au moins 10 caractères
  /// - Contient principalement des lettres et chiffres
  static bool looksLikeIsin(String query) {
    final cleaned = query.trim().toUpperCase().replaceAll(RegExp(r'\s'), '');

    if (cleaned.length < 10) return false;

    // Doit commencer par 2 lettres
    if (!RegExp(r'^[A-Z]{2}').hasMatch(cleaned)) {
      return false;
    }

    // Doit contenir principalement des alphanumériques
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleaned)) {
      return false;
    }

    return true;
  }

  /// Nettoie et formate une chaîne pour qu'elle ressemble à un ISIN
  ///
  /// Supprime les espaces et met en majuscules
  static String cleanIsin(String input) {
    return input.trim().toUpperCase().replaceAll(RegExp(r'\s'), '');
  }

  /// Liste des codes pays ISO 3166-1 alpha-2 valides pour les ISIN
  ///
  /// Note : Cette liste n'est pas exhaustive mais contient les principaux
  /// pays émetteurs de titres financiers.
  static const validCountryCodes = [
    'US', // États-Unis
    'FR', // France
    'DE', // Allemagne
    'GB', // Royaume-Uni
    'JP', // Japon
    'CH', // Suisse
    'CA', // Canada
    'NL', // Pays-Bas
    'IT', // Italie
    'ES', // Espagne
    'AU', // Australie
    'BE', // Belgique
    'SE', // Suède
    'DK', // Danemark
    'NO', // Norvège
    'FI', // Finlande
    'AT', // Autriche
    'IE', // Irlande
    'LU', // Luxembourg
    'HK', // Hong Kong
    'SG', // Singapour
    'KR', // Corée du Sud
    'CN', // Chine
    'IN', // Inde
    'BR', // Brésil
    // Ajoutez d'autres codes selon vos besoins
  ];

  /// Vérifie si le code pays de l'ISIN est dans la liste des codes connus
  static bool hasValidCountryCode(String isin) {
    if (isin.length < 2) return false;
    final countryCode = isin.substring(0, 2).toUpperCase();
    return validCountryCodes.contains(countryCode);
  }
}
