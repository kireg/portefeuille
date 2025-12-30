import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import '../theme/app_spacing.dart';


class AccountTypeChip extends StatelessWidget {
  final AccountType accountType;
  final bool isNoviceModeEnabled;

  const AccountTypeChip({
    super.key,
    required this.accountType,
    this.isNoviceModeEnabled = false, // Par défaut, le mode novice est désactivé
  });

  @override
  Widget build(BuildContext context) {
    final chip = Chip(
      label: Text(accountType.displayName),
      labelStyle: TextStyle(
        color: Colors.blueGrey[800],
        fontWeight: FontWeight.normal,
        fontSize: 11,
      ),
      backgroundColor: Colors.blueGrey[100],
      side: BorderSide.none,
      padding: AppSpacing.chipPaddingDefault,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (isNoviceModeEnabled) {
      return Tooltip(
        message: accountType.description,
        preferBelow: false, // Afficher l'info-bulle au-dessus pour éviter les décalages
        child: chip,
      );
    }

    return chip;
  }
}
