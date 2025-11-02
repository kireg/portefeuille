import 'asset.dart';
import 'account_type.dart';

/// Représente un compte financier (PEA, CTO, etc.) au sein d'une institution.
class Account {
  /// Nom du compte (ex: "PEA Boursorama")
  final String name;

  /// Type de compte
  final AccountType type;

  /// Liste des actifs détenus dans le compte
  List<Asset> assets;

  /// Solde de liquidités du compte
  double cashBalance;

  Account({
    required this.name,
    required this.type,
    this.assets = const [],
    this.cashBalance = 0.0,
  });

  /// Valeur totale du compte (actifs + liquidités)
  double get totalValue {
    final assetsValue = assets.fold(0.0, (sum, asset) => sum + asset.totalValue);
    return assetsValue + cashBalance;
  }

  // Méthodes pour la sérialisation JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      name: json['name'],
      type: AccountType.values.firstWhere((e) => e.toString() == json['type']),
      assets: (json['assets'] as List).map((i) => Asset.fromJson(i)).toList(),
      cashBalance: json['cashBalance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.toString(),
      'assets': assets.map((a) => a.toJson()).toList(),
      'cashBalance': cashBalance,
    };
  }
}
