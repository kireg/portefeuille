// lib/features/07_management/ui/screens/add_account_screen.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddAccountScreen extends StatefulWidget {
  final String institutionId;
  const AddAccountScreen({super.key, required this.institutionId});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cashController = TextEditingController(text: "0.0");
  AccountType _selectedType = AccountType.cto;
  final _uuid = const Uuid();

  @override
  void dispose() {
    _nameController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newAccount = Account(
        id: _uuid.v4(),
        name: _nameController.text,
        type: _selectedType,
        cashBalance: double.tryParse(_cashController.text) ?? 0.0,
        assets: [],
      );

      Provider.of<PortfolioProvider>(context, listen: false)
          .addAccount(widget.institutionId, newAccount);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    // MODIFIÉ : Retrait du Scaffold, ajout du SingleChildScrollView
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          bottom: keyboardPadding + 16.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ajouter un Compte',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nom du compte (ex: PEA, CTO)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type de compte',
                  border: OutlineInputBorder(),
                ),
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (type) {
                  setState(() {
                    if (type != null) {
                      _selectedType = type;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cashController,
                decoration: const InputDecoration(
                  labelText: 'Solde de liquidités (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro_symbol),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Enregistrer'),
              )
            ],
          ),
        ),
      ),
    );
  }
}