import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/institution_metadata.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_text_field.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

class AddInstitutionScreen extends StatefulWidget {
  final void Function(Institution)? onInstitutionCreated;
  final Institution? institutionToEdit;

  const AddInstitutionScreen({
    super.key, 
    this.onInstitutionCreated,
    this.institutionToEdit,
  });

  @override
  State<AddInstitutionScreen> createState() => _AddInstitutionScreenState();
}

class _AddInstitutionScreenState extends State<AddInstitutionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _searchFocusNode = FocusNode();
  final _uuid = const Uuid();
  
  bool _isSaving = false;
  List<InstitutionMetadata> _filteredInstitutions = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.institutionToEdit?.name ?? '');
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
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        if (widget.institutionToEdit != null) {
          // Mode Édition
          final updatedInstitution = widget.institutionToEdit!.copyWith(
            name: _nameController.text,
          );
          await Provider.of<PortfolioProvider>(context, listen: false)
              .updateInstitution(updatedInstitution);
        } else {
          // Mode Création
          final newInstitution = Institution(
            id: _uuid.v4(),
            name: _nameController.text,
            accounts: [],
          );

          if (widget.onInstitutionCreated != null) {
            widget.onInstitutionCreated!(newInstitution);
          } else {
            await Provider.of<PortfolioProvider>(context, listen: false)
                .addInstitution(newInstitution);
          }
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint("Erreur lors de la sauvegarde : $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors de la sauvegarde : $e")),
          );
          setState(() {
            _isSaving = false;
          });
        }
      }
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
              widget.institutionToEdit != null ? 'Modifier la banque' : 'Ajouter une banque',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppDimens.paddingL),

            AppTextField(
              controller: _nameController,
              focusNode: _searchFocusNode,
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
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppDimens.paddingS),

            Expanded(
              child: _filteredInstitutions.isEmpty 
                ? Center(child: Text("Aucune suggestion trouvée", style: AppTypography.body))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: AppDimens.paddingM,
                      mainAxisSpacing: AppDimens.paddingM,
                    ),
                    itemCount: _filteredInstitutions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _filteredInstitutions.length) {
                        return InkWell(
                          onTap: () {
                            FocusScope.of(context).requestFocus(_searchFocusNode);
                          },
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(AppDimens.radiusM),
                              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                            ),
                            padding: const EdgeInsets.all(AppDimens.paddingS),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.surfaceLight,
                                  child: Icon(Icons.add, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: AppDimens.paddingS),
                                Text(
                                  "Autre banque",
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final inst = _filteredInstitutions[index];
                      return InkWell(
                        onTap: () => _selectInstitution(inst),
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppDimens.radiusM),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blackOverlay05,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.all(AppDimens.paddingS),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: inst.logoAsset.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(AppDimens.paddingS),
                                        child: Image.asset(
                                          inst.logoAsset,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return CircleAvatar(
                                              backgroundColor: inst.primaryColor,
                                              foregroundColor: AppColors.white,
                                              child: Text(
                                                inst.name.isNotEmpty ? inst.name[0].toUpperCase() : '?',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 24,
                                        backgroundColor: inst.primaryColor,
                                        foregroundColor: AppColors.white,
                                        child: Text(
                                          inst.name.isNotEmpty ? inst.name[0].toUpperCase() : '?',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: AppDimens.paddingXS),
                              Text(
                                inst.name,
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
              onPressed: _isSaving ? null : _submitForm,
              icon: Icons.add,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
