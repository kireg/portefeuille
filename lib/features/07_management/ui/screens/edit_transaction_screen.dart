// lib/features/07_management/ui/screens/edit_transaction_screen.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/features/07_management/ui/widgets/transaction_form_body.dart';

class EditTransactionScreen extends StatelessWidget {
  final Transaction existingTransaction;

  const EditTransactionScreen({super.key, required this.existingTransaction});

  @override
  Widget build(BuildContext context) {
    // Le padding est géré ici pour s'adapter au clavier
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          bottom: keyboardPadding + 16.0,
        ),
        // Appelle le formulaire partagé en mode "Édition"
        child: TransactionFormBody(
          existingTransaction: existingTransaction,
        ),
      ),
    );
  }
}