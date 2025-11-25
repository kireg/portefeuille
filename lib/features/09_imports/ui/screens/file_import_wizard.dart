import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/features/09_imports/ui/widgets/wizard_step_file.dart';
import 'package:portefeuille/features/09_imports/ui/widgets/wizard_step_source.dart';
import 'package:portefeuille/features/09_imports/ui/screens/ai_import_config_screen.dart';

class FileImportWizard extends StatefulWidget {
  const FileImportWizard({super.key});

  @override
  State<FileImportWizard> createState() => _FileImportWizardState();
}

class _FileImportWizardState extends State<FileImportWizard> {
  int _currentStep = 0;
  PlatformFile? _selectedFile;
  String? _selectedSourceId;

  // Step 1: File Selection
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'xlsx', 'xls'],
        withData: true, // Important for web/some platforms to get bytes immediately if needed
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection : $e')),
      );
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  void _nextStep() {
    if (_currentStep == 1 && _selectedSourceId == 'other_ai') {
      // Redirect to AI Import Screen
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AiImportConfigScreen(),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // 85% height for bottom sheet
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header with Drag Handle & Navigation
          _buildHeader(),
          
          // Progress Indicator
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildStepContent(),
            ),
          ),

          // Footer Actions
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Assistant d\'Import',
                  style: AppTypography.h3,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the close button
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          _buildStepDot(0, isActive: _currentStep >= 0),
          _buildStepLine(isActive: _currentStep >= 1),
          _buildStepDot(1, isActive: _currentStep >= 1),
          _buildStepLine(isActive: _currentStep >= 2),
          _buildStepDot(2, isActive: _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildStepDot(int index, {required bool isActive}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: AppTypography.bodyBold.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppColors.primary : AppColors.surfaceLight,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return WizardStepFile(
          selectedFile: _selectedFile,
          onPickFile: _pickFile,
          onClearFile: _clearFile,
        );
      case 1:
        return WizardStepSource(
          selectedSourceId: _selectedSourceId,
          onSelectSource: (id) {
            setState(() {
              _selectedSourceId = id;
            });
          },
        );
      case 2:
        return const Center(child: Text("Étape 3 : Validation (À venir)"));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooter() {
    bool canGoNext = false;
    if (_currentStep == 0 && _selectedFile != null) canGoNext = true;
    if (_currentStep == 1 && _selectedSourceId != null) canGoNext = true;
    if (_currentStep == 2) canGoNext = true; // TODO: Check validation status

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButton(
                label: 'Précédent',
                type: AppButtonType.secondary,
                onPressed: _previousStep,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: AppButton(
              label: _currentStep == 2 ? 'Terminer' : 'Suivant',
              type: AppButtonType.primary,
              onPressed: canGoNext ? _nextStep : null,
            ),
          ),
        ],
      ),
    );
  }
}
