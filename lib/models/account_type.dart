import 'package:hive/hive.dart';

part 'account_type.g.dart';

/// Enum pour les différents types de comptes financiers.
@HiveType(typeId: 4)
enum AccountType {
  /// Plan d'Épargne en Actions
  @HiveField(0)
  pea("PEA", "Le Plan d'Épargne en Actions (PEA) est un produit d'épargne réglementé qui permet d'investir en actions d'entreprises européennes en bénéficiant d'une exonération d'impôt sur le revenu sous conditions."),

  /// Compte-Titres Ordinaire
  @HiveField(1)
  cto("CTO", "Le Compte-Titres Ordinaire (CTO) est un compte qui permet d'investir sur tous types de valeurs mobilières (actions, obligations, etc.) sans plafond et sans contrainte géographique."),

  /// Assurance Vie
  @HiveField(2)
  assuranceVie("Assurance Vie", "L'Assurance Vie est un produit d'épargne qui permet de se constituer un capital ou une rente, tout en bénéficiant d'un cadre fiscal avantageux, notamment pour la transmission de patrimoine."),

  /// Plan Épargne Retraite
  @HiveField(3)
  per("PER", "Le Plan d'Épargne Retraite (PER) est un produit d'épargne à long terme qui permet de se constituer un capital ou une rente pour la retraite, tout en bénéficiant d'avantages fiscaux sur les versements."),

  /// Portefeuille de crypto-monnaies
  @HiveField(4)
  crypto("Crypto", "Un portefeuille de crypto-monnaies permet de détenir, d'envoyer et de recevoir des devises numériques comme le Bitcoin ou l'Ethereum."),

  /// Autre type de compte
  @HiveField(5)
  autre("Autre", "Tout autre type de compte d'investissement qui ne correspond pas aux catégories précédentes.");

  const AccountType(this.displayName, this.description);

  final String displayName;
  final String description;
}
