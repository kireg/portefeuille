import 'package:hive/hive.dart';

part 'account_type.g.dart';

/// Enum pour les différents types de comptes financiers.
@HiveType(typeId: 4)
enum AccountType {
  /// Plan d'Épargne en Actions
  @HiveField(0)
  pea,

  /// Compte-Titres Ordinaire
  @HiveField(1)
  cto,

  /// Assurance Vie
  @HiveField(2)
  assuranceVie,

  /// Plan Épargne Retraite
  @HiveField(3)
  per,

  /// Portefeuille de crypto-monnaies
  @HiveField(4)
  crypto,

  /// Autre type de compte
  @HiveField(5)
  autre,
}
