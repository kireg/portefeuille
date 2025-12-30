import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/models/repayment_type.dart';
import 'package:portefeuille/features/07_management/ui/providers/transaction_form_state.dart';
import 'package:portefeuille/core/Design_Center/widgets/inputs/app_text_field.dart';
import 'package:portefeuille/core/Design_Center/widgets/inputs/app_dropdown.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';

class CrowdfundingFields extends StatelessWidget {
  const CrowdfundingFields({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFormState>();
    final readState = context.read<TransactionFormState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimens.paddingM),
        const Divider(),
        const SizedBox(height: AppDimens.paddingM),
        const Text("Détails Crowdfunding", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppDimens.paddingM),

        // Plateforme supprimée (gérée par l'Institution)

        AppTextField(
          controller: state.locationController,
          label: 'Localisation',
          hint: 'Ex: Paris, France',
          errorText: state.locationError,
        ),
        const SizedBox(height: AppDimens.paddingM),

        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: state.minDurationController,
                label: 'Durée Min (mois)',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: AppTextField(
                controller: state.targetDurationController,
                label: 'Cible',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: AppTextField(
                controller: state.maxDurationController,
                label: 'Max',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),

        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: state.expectedYieldController,
                label: 'Rendement Cible (%)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: AppTextField(
                controller: state.riskRatingController,
                label: 'Note Risque',
                hint: 'Ex: A+',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),

        AppDropdown<RepaymentType>(
          label: 'Type de Remboursement',
          value: state.selectedRepaymentType,
          items: RepaymentType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (type) => readState.setRepaymentType(type),
        ),
      ],
    );
  }
}
