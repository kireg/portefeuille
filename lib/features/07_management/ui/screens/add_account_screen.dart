// lib/features/07_management/ui/screens/add_account_screen.dart
// REMPLACEZ LE FICHIER COMPLET

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddAccountScreen extends StatefulWidget {
  final String institutionId;
  final void Function(Account)? onAccountCreated;

  const AddAccountScreen({
    super.key,
    required this.institutionId,
    this.onAccountCreated,
  });
  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  AccountType _selectedType = AccountType.cto;
  String _selectedCurrency = 'EUR'; // <-- NOUVEAU
  final _uuid = const Uuid();

  // Liste simplifiée des devises
  final List<String> _currencies = ['EUR', 'USD', 'CHF', 'GBP', 'CAD', 'JPY'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newAccount = Account(
        id: _uuid.v4(),
        name: _nameController.text,
        type: _selectedType,
        currency: _selectedCurrency, // <-- MODIFIÉ
      );

      if (widget.onAccountCreated != null) {
        widget.onAccountCreated!(newAccount);
      } else {
        Provider.of<PortfolioProvider>(context, listen: false)
            .addAccount(widget.institutionId, newAccount);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
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
              const SizedBox(height: 16), // <-- DEBUT AJOUT
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Devise du compte',
                  border: OutlineInputBorder(),
                ),
                items: _currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (currency) {
                  setState(() {
                    if (currency != null) {
                      _selectedCurrency = currency;
                    }
                  });
                },
              ), // <-- FIN AJOUT
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