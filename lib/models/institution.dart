import 'account.dart';

/// Représente un établissement financier (banque, courtier, etc.)
class Institution {
  /// Nom de l'établissement (ex: "Boursorama")
  final String name;

  /// Liste des comptes détenus dans cet établissement
  List<Account> accounts;

  Institution({required this.name, this.accounts = const []});

  /// Valeur totale de tous les comptes dans cet établissement
  double get totalValue {
    return accounts.fold(0.0, (sum, account) => sum + account.totalValue);
  }

  // Méthodes pour la sérialisation JSON
  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      name: json['name'],
      accounts: (json['accounts'] as List).map((i) => Account.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'accounts': accounts.map((a) => a.toJson()).toList(),
    };
  }
}
