import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';

/// Modèle intermédiaire pour une transaction extraite d'un PDF.
/// Elle n'est pas encore une [Transaction] finale car il peut manquer des infos (ex: Ticker).
class ParsedTransaction {
  final DateTime date;
  final TransactionType type;
  final String assetName;
  final String? isin;
  final String? ticker;
  final double quantity;
  final double price;
  final double amount;
  final double fees;
  final String currency;
  final AssetType? assetType;

  ParsedTransaction({
    required this.date,
    required this.type,
    required this.assetName,
    this.isin,
    this.ticker,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.fees,
    required this.currency,
    this.assetType,
  });

  @override
  String toString() {
    return 'ParsedTransaction(date: $date, type: $type, asset: $assetName, qty: $quantity, price: $price, amount: $amount, assetType: $assetType)';
  }
}

/// Interface que tout parser de relevé bancaire doit implémenter.
abstract class StatementParser {
  /// Nom de la banque (ex: "Trade Republic")
  String get bankName;

  /// Vérifie si le contenu brut du PDF correspond à cette banque.
  bool canParse(String rawText);

  /// Message d'avertissement optionnel à afficher à l'utilisateur.
  String? get warningMessage => null;

  /// Extrait les transactions du texte brut.
  /// [onProgress] est appelé avec une valeur entre 0.0 et 1.0 pour indiquer la progression.
  Future<List<ParsedTransaction>> parse(String rawText, {void Function(double)? onProgress});
}
