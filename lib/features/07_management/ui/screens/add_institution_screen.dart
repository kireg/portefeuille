import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/institution_metadata.dart';
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
  
  List<InstitutionMetadata> _filteredInstitutions = [];

  @override
  void initState() {
    super.initState();
    // Initial load of suggestions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSuggestions('');
    });
  }

  void _updateSuggestions(String query) {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    setState(() {
      _filteredInstitutions = provider.institutionService.search(query);
    });
  }

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
  
  void _selectInstitution(InstitutionMetadata metadata) {
    _nameController.text = metadata.name;
    _submitForm();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.fromLTRB(
        AppDimens.paddingL,
        AppDimens.paddingL,
        AppDimens.paddingL,
        keyboardPadding + AppDimens.paddingL,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajouter une banque',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppDimens.paddingL),

            AppTextField(
              controller: _nameController,
              label: 'Nom de l\'établissement',
              hint: 'Rechercher ou saisir...',
              prefixIcon: Icons.search,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: _updateSuggestions,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimens.paddingM),
            
            Text(
              'Suggestions',
              style: AppTypography.caption.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: AppDimens.paddingS),

            Expanded(
              child: _filteredInstitutions.isEmpty 
                ? Center(child: Text("Aucune suggestion trouvée", style: AppTypography.body))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: AppDimens.paddingS,
                      mainAxisSpacing: AppDimens.paddingS,
                    ),
                    itemCount: _filteredInstitutions.length,
                    itemBuilder: (context, index) {
                      final inst = _filteredInstitutions[index];
                      return InkWell(
                        onTap: () => _selectInstitution(inst),
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(AppDimens.radiusM),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: inst.primaryColor,
                                foregroundColor: Colors.white,
                                child: Text(
                                  inst.name.isNotEmpty ? inst.name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: AppDimens.paddingS),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  inst.name,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption.copyWith(fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),

            const SizedBox(height: AppDimens.paddingL),

            AppButton(
              label: 'Créer manuellement',
              onPressed: _submitForm,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}