import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

// Core UI
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_text_field.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_dropdown.dart';

class AddAccountScreen extends StatefulWidget {
  final String institutionId;
  final Account? accountToEdit;
  final void Function(Account)? onAccountCreated;

  const AddAccountScreen({
    super.key,
    required this.institutionId,
    this.accountToEdit,
    this.onAccountCreated,
  });
  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  AccountType _selectedType = AccountType.cto;
  String _selectedCurrency = 'EUR';
  final _uuid = const Uuid();

  final List<String> _currencies = ['EUR', 'USD', 'CHF', 'GBP', 'CAD', 'JPY'];

  bool get _isEditing => widget.accountToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final account = widget.accountToEdit!;
      _nameController.text = account.name;
      _selectedType = account.type;
      _selectedCurrency = account.currency ?? 'EUR';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<PortfolioProvider>(context, listen: false);

      if (_isEditing) {
        final oldAccount = widget.accountToEdit!;
        final updatedAccount = Account(
          id: oldAccount.id,
          name: _nameController.text,
          type: _selectedType,
          currency: oldAccount.currency, // Non modifiable
        );
        updatedAccount.assets = oldAccount.assets;
        updatedAccount.transactions = oldAccount.transactions;
        provider.updateAccount(widget.institutionId, updatedAccount);
      } else {
        final newAccount = Account(
          id: _uuid.v4(),
          name: _nameController.text,
          type: _selectedType,
          currency: _selectedCurrency,
        );
        if (widget.onAccountCreated != null) {
          widget.onAccountCreated!(newAccount);
        } else {
          provider.addAccount(widget.institutionId, newAccount);
        }
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimens.paddingL,
          AppDimens.paddingL,
          AppDimens.paddingL,
          keyboardPadding + AppDimens.paddingL,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Modifier le Compte' : 'Nouveau Compte',
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppDimens.paddingL),

              // Nom
              AppTextField(
                controller: _nameController,
                label: 'Nom du compte',
                hint: 'ex: PEA, CTO...',
                prefixIcon: Icons.account_balance_wallet,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppDimens.paddingM),

              // Type
              AppDropdown<AccountType>(
                label: 'Type de compte',
                value: _selectedType,
                prefixIcon: Icons.category,
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (type) {
                  if (type != null) setState(() => _selectedType = type);
                },
              ),
              const SizedBox(height: AppDimens.paddingM),

              // Devise
              AppDropdown<String>(
                label: 'Devise',
                value: _selectedCurrency,
                prefixIcon: Icons.currency_exchange,
                // Désactivé en édition
                onChanged: _isEditing ? null : (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
                items: _currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppDimens.paddingL),

              AppButton(
                label: _isEditing ? 'Enregistrer' : 'Créer',
                icon: _isEditing ? Icons.save : Icons.add,
                onPressed: _submitForm,
              )
            ],
          ),
        ),
      ),
    );
  }
}