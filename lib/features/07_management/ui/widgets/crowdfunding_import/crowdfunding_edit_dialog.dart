import 'package:flutter/material.dart';
import 'package:portefeuille/features/07_management/services/excel/parsed_crowdfunding_project.dart';
import 'package:portefeuille/core/data/models/repayment_type.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';

class CrowdfundingEditDialog extends StatefulWidget {
  final ParsedCrowdfundingProject project;
  final Function(ParsedCrowdfundingProject) onSave;

  const CrowdfundingEditDialog({
    super.key,
    required this.project,
    required this.onSave,
  });

  @override
  State<CrowdfundingEditDialog> createState() => _CrowdfundingEditDialogState();
}

class _CrowdfundingEditDialogState extends State<CrowdfundingEditDialog> {
  late TextEditingController nameController;
  late TextEditingController amountController;
  late TextEditingController yieldController;
  late TextEditingController minDurationController;
  late TextEditingController targetDurationController;
  late TextEditingController maxDurationController;
  late TextEditingController cityController;
  late RepaymentType selectedRepayment;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    nameController = TextEditingController(text: project.projectName);
    amountController = TextEditingController(text: project.investedAmount.toString());
    yieldController = TextEditingController(text: project.yieldPercent.toString());
    minDurationController = TextEditingController(text: (project.minDurationMonths ?? project.durationMonths).toString());
    targetDurationController = TextEditingController(text: project.durationMonths.toString());
    maxDurationController = TextEditingController(text: (project.maxDurationMonths ?? project.durationMonths).toString());
    cityController = TextEditingController(text: project.city ?? '');
    selectedRepayment = project.repaymentType;
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    yieldController.dispose();
    minDurationController.dispose();
    targetDurationController.dispose();
    maxDurationController.dispose();
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: Text('Modifier le projet', style: AppTypography.h3),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom du projet'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Montant (€)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: yieldController,
                      decoration: const InputDecoration(labelText: 'Rendement (%)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minDurationController,
                      decoration: const InputDecoration(labelText: 'Durée Min (mois)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: targetDurationController,
                      decoration: const InputDecoration(labelText: 'Durée Cible (mois)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: maxDurationController,
                      decoration: const InputDecoration(labelText: 'Durée Max (mois)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<RepaymentType>(
                value: selectedRepayment,
                decoration: const InputDecoration(labelText: 'Remboursement'),
                items: RepaymentType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.displayName),
                )).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedRepayment = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final newProject = ParsedCrowdfundingProject(
              projectName: nameController.text,
              platform: widget.project.platform,
              investmentDate: widget.project.investmentDate,
              investedAmount: double.tryParse(amountController.text) ?? widget.project.investedAmount,
              yieldPercent: double.tryParse(yieldController.text) ?? widget.project.yieldPercent,
              durationMonths: int.tryParse(targetDurationController.text) ?? widget.project.durationMonths,
              minDurationMonths: int.tryParse(minDurationController.text),
              maxDurationMonths: int.tryParse(maxDurationController.text),
              repaymentType: selectedRepayment,
              city: cityController.text,
              country: widget.project.country,
              riskRating: widget.project.riskRating,
            );
            widget.onSave(newProject);
            Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
