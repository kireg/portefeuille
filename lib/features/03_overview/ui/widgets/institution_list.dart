import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'account_tile.dart';

class InstitutionList extends StatelessWidget {
  final List<Institution> institutions;

  const InstitutionList({super.key, required this.institutions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true, // Important pour l'imbrication dans un SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // La vue parente gère le scroll
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
            children: institution.accounts.map((account) {
              return AccountTile(account: account);
            }).toList(),
          ),
        );
      },
    );
  }
}
