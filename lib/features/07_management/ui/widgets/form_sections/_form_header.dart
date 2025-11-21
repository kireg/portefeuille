import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';

class FormHeader extends StatelessWidget {
  const FormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          state.isEditing ? 'Modifier' : 'Nouvelle Transaction',
          style: AppTypography.h2,
        ),
        AppIcon(
          icon: Icons.close,
          onTap: () => Navigator.of(context).pop(),
          backgroundColor: Colors.transparent,
          size: 24,
        ),
      ],
    );
  }
}