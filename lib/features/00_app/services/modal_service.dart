// lib/features/00_app/services/modal_service.dart
// Service centré pour présenter des BottomSheets applicatifs.
// Centralise les imports d'écrans (Feature 07) afin d'éviter les imports inter-features.

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_institution_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_account_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_transaction_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_savings_plan_screen.dart';

class ModalService {
  ModalService._();

  static Future<T?> _show<T>(BuildContext context, Widget child) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (context) => child,
    );
  }

  static Future<void> showAddInstitution(BuildContext context, {void Function(Institution)? onInstitutionCreated, Institution? institutionToEdit}) async {
    await _show<void>(context, AddInstitutionScreen(
      onInstitutionCreated: onInstitutionCreated,
      institutionToEdit: institutionToEdit,
    ));
  }

  static Future<void> showAddAccount(BuildContext context, {required String institutionId, Account? accountToEdit, void Function(Account)? onAccountCreated}) async {
    await _show<void>(context, AddAccountScreen(
      institutionId: institutionId,
      accountToEdit: accountToEdit,
      onAccountCreated: onAccountCreated,
    ));
  }

  static Future<void> showAddTransaction(BuildContext context, {dynamic transactionToEdit}) async {
    await _show<void>(context, const AddTransactionScreen());
  }

  static Future<void> showAddSavingsPlan(BuildContext context) async {
    await _show<void>(context, const AddSavingsPlanScreen());
  }
}
