import 'institution.dart';

/// Représente l'ensemble du portefeuille de l'utilisateur.
class Portfolio {
  /// Liste des établissements financiers du portefeuille
  List<Institution> institutions;

  Portfolio({this.institutions = const []});

  /// Valeur totale de l'ensemble du portefeuille
  double get totalValue {
    return institutions.fold(0.0, (sum, inst) => sum + inst.totalValue);
  }

  // Méthodes pour la sérialisation JSON
  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      institutions: (json['institutions'] as List)
          .map((i) => Institution.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institutions': institutions.map((i) => i.toJson()).toList(),
    };
  }
}
