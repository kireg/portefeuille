// lib/core/utils/enum_helpers.dart

/// Helper pour convertir un nom (String) en Enum de manière sécurisée
/// Tente de trouver la valeur par son nom (ex: "Buy").
/// Renvoie [fallback] si [value] est null ou introuvable.
T enumFromString<T>(List<T> values, String? value, {required T fallback}) {
  if (value == null) {
    return fallback;
  }
  try {
    // Utilise .name (ex: TransactionType.Buy.name -> "Buy")
    return values.firstWhere(
          (type) => (type as Enum).name.toLowerCase() == value.toLowerCase(),
    );
  } catch (e) {
    // Si .firstWhere échoue (valeur non trouvée)
    return fallback;
  }
}

/// Helper pour la conversion en JSON, en utilisant .name
/// (ex: TransactionType.Buy -> "Buy")
String? enumToString<T>(T? value) {
  if (value == null) return null;
  return (value as Enum).name;
}