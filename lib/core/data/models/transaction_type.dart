// ignore_for_file: constant_identifier_names
import 'package:hive/hive.dart';

part 'transaction_type.g.dart';

@HiveType(typeId: 6) // IMPORTANT: Utilisez un ID non utilisé (ex: 6)
enum TransactionType {
  @HiveField(0)
  Deposit, // Dépôt de liquidités

  @HiveField(1)
  Withdrawal, // Retrait de liquidités

  @HiveField(2)
  Buy, // Achat d'actif

  @HiveField(3)
  Sell, // Vente d'actif

  @HiveField(4)
  Dividend, // Dividende reçu (en liquidités)

  @HiveField(5)
  Interest, // Intérêts reçus (sur liquidités)

  @HiveField(6)
  Fees, // Frais (débités des liquidités)

  // @HiveField(7) - SUPPRIMÉ (InterestPayment)
  // On utilise Interest pour les intérêts reçus, quel que soit l'actif.

  @HiveField(8)
  CapitalRepayment, // Remboursement de capital (Crowdfunding)

  @HiveField(9)
  EarlyRepayment, // Remboursement anticipé (Crowdfunding)
}
/// Extension pour la traduction et les métadonnées de TransactionType
extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.Deposit:
        return 'Dépôt';
      case TransactionType.Withdrawal:
        return 'Retrait';
      case TransactionType.Buy:
        return 'Achat';
      case TransactionType.Sell:
        return 'Vente';
      case TransactionType.Dividend:
        return 'Dividende';
      case TransactionType.Interest:
        return 'Intérêts';
      case TransactionType.Fees:
        return 'Frais';
      case TransactionType.CapitalRepayment:
        return 'Remboursement Capital';
      case TransactionType.EarlyRepayment:
        return 'Remboursement Anticipé';
    }
  }
}