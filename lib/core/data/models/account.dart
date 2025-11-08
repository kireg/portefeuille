import 'package:hive/hive.dart';
import 'asset.dart';
import 'account_type.dart';

part 'account.g.dart';

@HiveType(typeId: 2)
class Account {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final AccountType type;

  @HiveField(2)
  List<Asset> assets;

  @HiveField(3)
  double cashBalance;

  @HiveField(4)
  final String id; // NOUVEAU

  Account({
    required this.id, // MIS À JOUR
    required this.name,
    required this.type,
    this.assets = const [],
    this.cashBalance = 0.0,
  });

  double get totalValue {
    final assetsValue =
    assets.fold(0.0, (sum, asset) => sum + asset.totalValue);
    return assetsValue + cashBalance;
  }

  double get profitAndLoss {
    return assets.fold(0.0, (sum, asset) => sum + asset.profitAndLoss);
  }

  double get estimatedAnnualYield {
    final assetsValue =
    assets.fold(0.0, (sum, asset) => sum + asset.totalValue);
    if (assetsValue == 0) {
      return 0.0;
    }
    final weightedYield = assets.fold(
        0.0,
            (sum, asset) =>
        sum + (asset.totalValue * asset.estimatedAnnualYield));
    return weightedYield / assetsValue;
  }

  Account deepCopy() {
    return Account(
      id: id, // MIS À JOUR
      name: name,
      type: type,
      cashBalance: cashBalance,
      assets: assets.map((asset) => asset.deepCopy()).toList(),
    );
  }
}