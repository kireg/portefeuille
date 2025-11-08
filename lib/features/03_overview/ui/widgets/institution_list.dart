// lib/features/03_overview/ui/widgets/institution_list.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'account_tile.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_account_screen.dart';

class InstitutionList extends StatelessWidget {
  final List<Institution> institutions;
  const InstitutionList({super.key, required this.institutions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: institutions.length,
      itemBuilder: (context, index) {
        final institution = institutions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ExpansionTile(
            title: Text(
              institution.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              CurrencyFormatter.format(institution.totalValue),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              ...institution.accounts.map((account) {
                return AccountTile(account: account);
              }).toList(),
              ListTile(
                leading: Icon(Icons.add, color: Colors.grey[400]),
                title: Text(
                  'Ajouter un compte',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                // --- MODIFIÉ ---
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        AddAccountScreen(institutionId: institution.id),
                  );
                },
                // --- FIN MODIFICATION ---
              ),
            ],
          ),
        );
      },
    );
  }
}