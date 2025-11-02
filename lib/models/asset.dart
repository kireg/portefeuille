/// Représente un actif financier individuel (action, ETF, etc.)
class Asset {
  /// Nom de l'actif (ex: "Apple Inc.")
  final String name;

  /// Symbole boursier ou ticker (ex: "AAPL")
  final String ticker;

  /// Quantité d'actifs détenus
  double quantity;

  /// Prix de Revient Unitaire (PRU)
  double averagePrice;

  /// Prix actuel du marché
  double currentPrice;

  Asset({
    required this.name,
    required this.ticker,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
  });

  /// Valeur totale de l'actif
  double get totalValue => quantity * currentPrice;

  /// Plus-value ou moins-value latente
  double get profitAndLoss => (currentPrice - averagePrice) * quantity;

  /// Plus-value ou moins-value en pourcentage
  double get profitAndLossPercentage {
    if (averagePrice == 0) return 0.0;
    return (currentPrice / averagePrice - 1);
  }

  // Méthodes pour la sérialisation JSON (à implémenter avec Hive/Isar)
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      name: json['name'],
      ticker: json['ticker'],
      quantity: json['quantity'],
      averagePrice: json['averagePrice'],
      currentPrice: json['currentPrice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ticker': ticker,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'currentPrice': currentPrice,
    };
  }
}
