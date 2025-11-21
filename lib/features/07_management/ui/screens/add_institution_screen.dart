import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

// Core UI
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_text_field.dart';

class AddInstitutionScreen extends StatefulWidget {
  final void Function(Institution)? onInstitutionCreated;

  const AddInstitutionScreen({super.key, this.onInstitutionCreated});

  @override
  State<AddInstitutionScreen> createState() => _AddInstitutionScreenState();
}

class _AddInstitutionScreenState extends State<AddInstitutionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newInstitution = Institution(
        id: _uuid.v4(),
        name: _nameController.text,
        accounts: [],
      );

      if (widget.onInstitutionCreated != null) {
        widget.onInstitutionCreated!(newInstitution);
      } else {
        Provider.of<PortfolioProvider>(context, listen: false)
            .addInstitution(newInstitution);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    // Pas besoin de Scaffold ou AppScreen ici car c'est un BottomSheet
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
                'Nouvelle Banque', // Titre plus court et punchy
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppDimens.paddingL),

              // Notre nouveau champ de texte
              AppTextField(
                controller: _nameController,
                label: 'Nom de l\'établissement',
                hint: 'ex: Boursorama, Binance...',
                prefixIcon: Icons.account_balance,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimens.paddingL),

              // Notre nouveau bouton
              AppButton(
                label: 'Créer',
                onPressed: _submitForm,
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ),
    );
  }
}