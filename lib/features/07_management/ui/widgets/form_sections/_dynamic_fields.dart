// lib/features/07_management/ui/widgets/form_sections/_dynamic_fields.dart
import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:provider/provider.dart';
import '_asset_fields.dart';
import '_cash_fields.dart';
import '_dividend_fields.dart';

class DynamicFields extends StatelessWidget {
  const DynamicFields({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedType = context.watch<TransactionFormState>().selectedType;

    switch (selectedType) {
      case TransactionType.Deposit:
      case TransactionType.Withdrawal:
      case TransactionType.Interest:
      case TransactionType.Fees:
        return const CashFields();
      case TransactionType.Dividend:
        return const DividendFields();
      case TransactionType.Buy:
      case TransactionType.Sell:
        return const AssetFields();
      // case TransactionType.InterestPayment: // SUPPRIMÉ
      case TransactionType.CapitalRepayment:
      case TransactionType.EarlyRepayment:
        // Pour l'instant, on utilise CashFields car ce sont des flux d'argent liés à un actif
        // Idéalement, on pourrait avoir un CrowdfundingFields spécifique si besoin
        return const CashFields();
    }
  }
}