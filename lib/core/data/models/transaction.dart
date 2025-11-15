// lib/core/data/models/transaction.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:hive/hive.dart';
import 'transaction_type.dart';
import 'asset_type.dart';

part 'transaction.g.dart';

@HiveType(typeId: 7) // IMPORTANT: Utilisez un ID non utilisé (ex: 7)
class Transaction {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String accountId; // Compte parent

  @HiveField(2)
  final TransactionType type;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? assetTicker; // Ticker de l'actif (pour Achat/Vente/Dividende)

  @HiveField(5)
  final String? assetName; // Nom de l'actif

  @HiveField(6)
  final double? quantity; // Quantité d'actifs (pour Achat/Vente)

  @HiveField(7)
  final double? price; // Prix unitaire DANS LA DEVISE DE L'ACTIF (ex: 150.00 USD)

  @HiveField(8)
  final double amount; // Montant DANS LA DEVISE DU COMPTE (ex: -140.00 EUR)

  @HiveField(9)
  final double fees; // Frais DANS LA DEVISE DU COMPTE (ex: 2.00 EUR)

  @HiveField(10)
  final String notes;

  @HiveField(11)
  final AssetType? assetType; // Pour Achat/Vente

  // --- NOUVEAUX CHAMPS DEVISE ---
  @HiveField(12)
  final String?
  priceCurrency; // Devise du 'price' (ex: "USD" pour AAPL)

  @HiveField(13)
  final double?
  exchangeRate; // Taux de change (priceCurrency -> account.currency) ex: 1.08
  // --- FIN NOUVEAUX CHAMPS ---

  Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.date,
    required this.amount,
    this.assetTicker,
    this.assetName,
    this.quantity,
    this.price,
    this.priceCurrency, // <-- MODIFIÉ
    this.exchangeRate, // <-- MODIFIÉ
    this.fees = 0.0,
    this.notes = '',
    this.assetType,
  });

  // Helper pour obtenir le montant total de la transaction (ex: Achat)
  // 'amount' et 'fees' SONT TOUS LES DEUX dans la devise du compte.
  // Cette logique reste donc inchangée.
  double get totalAmount {
    // Pour un achat, amount = (quantity * price * exchangeRate) * -1
    // Pour une vente, amount = (quantity * price * exchangeRate)
    // Pour un dépôt, amount = montant
    // 'amount' stocke déjà le résultat de ce calcul.
    return amount - fees;
  }
}