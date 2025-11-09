// lib/features/04_correction/ui/widgets/correction_content.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/features/04_correction/ui/widgets/institution_card.dart';

/// Affiche le contenu principal (bouton + liste des institutions)
class CorrectionContent extends StatelessWidget {
  final Key listKey;
  final List<Institution> institutions;
  final VoidCallback onAddInstitution;
  final void Function(int) onDeleteInstitution;
  final void Function(int) onAddAccount;
  final void Function(int, int) onDeleteAccount;
  final void Function(int, int) onAddAsset;
  final void Function(int, int, int) onDeleteAsset;
  final VoidCallback onDataChanged;

  const CorrectionContent({
    super.key,
    required this.listKey,
    required this.institutions,
    required this.onAddInstitution,
    required this.onDeleteInstitution,
    required this.onAddAccount,
    required this.onDeleteAccount,
    required this.onAddAsset,
    required this.onDeleteAsset,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OutlinedButton.icon(
            onPressed: onAddInstitution,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une Institution'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: listKey,
            padding: const EdgeInsets.all(8.0),
            itemCount: institutions.length,
            itemBuilder: (context, instIndex) {
              final inst = institutions[instIndex];
              return InstitutionCard(
                institution: inst,
                onDelete: () => onDeleteInstitution(instIndex),
                onAddAccount: () => onAddAccount(instIndex),
                onDeleteAccount: (accIndex) =>
                    onDeleteAccount(instIndex, accIndex),
                onAddAsset: (accIndex) => onAddAsset(instIndex, accIndex),
                onDeleteAsset: (accIndex, assetIndex) =>
                    onDeleteAsset(instIndex, accIndex, assetIndex),
                onDataChanged: onDataChanged,
              );
            },
          ),
        ),
      ],
    );
  }
}
