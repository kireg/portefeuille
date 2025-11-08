import 'package:hive/hive.dart';

part 'asset.g.dart';

@HiveType(typeId: 3)
class Asset {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String ticker;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  double averagePrice;

  @HiveField(4)
  double currentPrice;

  @HiveField(5)
  double estimatedAnnualYield;

  @HiveField(6)
  final String id; // NOUVEAU

  Asset({
    required this.id, // MIS À JOUR
    required this.name,
    required this.ticker,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    this.estimatedAnnualYield = 0.0,
  });

  double get totalValue => quantity * currentPrice;

  double get profitAndLoss => (currentPrice - averagePrice) * quantity;

  double get profitAndLossPercentage {
    if (averagePrice == 0) return 0.0;
    return (currentPrice / averagePrice - 1);
  }

  Asset deepCopy() {
    return Asset(
      id: id, // MIS À JOUR
      name: name,
      ticker: ticker,
      quantity: quantity,
      averagePrice: averagePrice,
      currentPrice: currentPrice,
      estimatedAnnualYield: estimatedAnnualYield,
    );
  }
}