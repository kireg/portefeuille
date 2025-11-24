import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/models/transaction_extraction_result.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

/// Représente une transaction en cours d'édition avant import final.
class DraftTransaction {
  final String id;
  DateTime date;
  TransactionType type;
  AssetType assetType; // Champ ajouté
  String ticker;
  String name;
  double amount;
  double quantity;
  double price;
  double fees;
  String currency;

  // Indicateurs de validation
  bool isDuplicate;

  DraftTransaction({
    required this.date,
    required this.type,
    this.assetType = AssetType.Stock,
    this.ticker = '',
    this.name = '',
    this.amount = 0.0,
    this.quantity = 0.0,
    this.price = 0.0,
    this.fees = 0.0,
    this.currency = 'EUR',
    this.isDuplicate = false,
  }) : id = const Uuid().v4();

  factory DraftTransaction.fromExtraction(TransactionExtractionResult result) {
    return DraftTransaction(
      date: result.date ?? DateTime.now(),
      type: result.type ?? TransactionType.Buy,
      assetType: result.assetType ?? AssetType.Stock,
      ticker: result.ticker ?? '',
      name: result.name ?? '',
      amount: result.amount ?? 0.0,
      quantity: result.quantity ?? 0.0,
      price: result.price ?? 0.0,
      fees: result.fees ?? 0.0,
      currency: result.currency ?? 'EUR',
    );
  }
}