import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';
import 'package:portefeuille/features/09_imports/services/source_detector.dart';
import 'package:portefeuille/features/09_imports/ui/widgets/wizard_step_file.dart';
import 'package:portefeuille/features/09_imports/ui/widgets/wizard_step_source.dart';
import 'package:portefeuille/features/09_imports/ui/screens/ai_import_config_screen.dart';
import 'package:portefeuille/features/09_imports/services/import_save_service.dart';
import 'package:portefeuille/features/09_imports/ui/screens/file_import_wizard/wizard_state.dart';
import 'package:portefeuille/features/09_imports/ui/screens/file_import_wizard/wizard_parsing_service.dart';
import 'package:portefeuille/features/09_imports/ui/screens/file_import_wizard/wizard_validation_step.dart';
import 'package:portefeuille/features/09_imports/ui/screens/file_import_wizard/wizard_header.dart';
import 'package:portefeuille/features/09_imports/ui/screens/file_import_wizard/wizard_footer.dart';

/// Assistant d'import de fichiers en 3 étapes.
/// 
/// Étape 0: Sélection du fichier (PDF, CSV, Excel)
/// Étape 1: Sélection de la source (Boursorama, Revolut, etc.)
/// Étape 2: Validation et import des transactions
class FileImportWizard extends StatefulWidget {
  const FileImportWizard({super.key});

  @override
  State<FileImportWizard> createState() => _FileImportWizardState();
}

class _FileImportWizardState extends State<FileImportWizard> {
  final WizardState _state = WizardState();
  final WizardParsingService _parsingService = WizardParsingService();

  // ══════════════════════════════════════════════════════════════════════════
  // FILE SELECTION (Step 0)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        setState(() {
          _state.selectedFile = file;
          _state.detectionResult = null;
          _state.isDetecting = true;
        });
        await _detectSource(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection : $e')),
        );
      }
    }
  }

  Future<void> _detectSource(PlatformFile file) async {
    try {
      final detection = await _parsingService.detectSource(file);
      if (mounted) {
        setState(() {
          _state.detectionResult = detection;
          _state.isDetecting = false;
          if (detection.isDetected && detection.sourceId != null) {
            _state.selectedSourceId = detection.sourceId;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state.isDetecting = false;
          _state.detectionResult = SourceDetectionResult(
            message: 'Erreur lors de la détection: $e',
          );
        });
      }
    }
  }

  void _clearFile() {
    setState(() {
      _state.resetForNewFile();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ══════════════════════════════════════════════════════════════════════════

  void _nextStep() {
    if (_state.currentStep == 1 && _state.selectedSourceId == 'other_ai') {
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AiImportConfigScreen(),
      );
      return;
    }

    if (_state.currentStep < 2) {
      setState(() {
        _state.currentStep++;
      });

      if (_state.currentStep == 2) {
        _parseFile();
      }
    } else if (_state.currentStep == 2) {
      _saveTransactions();
    }
  }

  void _previousStep() {
    if (_state.currentStep > 0) {
      setState(() {
        _state.currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PARSING (Step 2)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _parseFile() async {
    if (_state.selectedFile == null || _state.selectedSourceId == null) return;

    setState(() {
      _state.prepareForParsing();
    });

    try {
      final portfolioProvider = context.read<PortfolioProvider>();
      final existingTransactions =
          collectExistingTransactions(portfolioProvider);

      final diff = await _parsingService.parseFile(
        file: _state.selectedFile!,
        sourceId: _state.selectedSourceId!,
        state: _state,
        trCategory: _state.selectedTrCategory,
        existingTransactions: existingTransactions,
        importMode: _state.importMode,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _state.parsingProgress = progress;
            });
          }
        },
      );

      setState(() {
        _state.candidates = diff.candidates;
        _state.duplicateTransactions = diff.duplicates;
        _state.invalidIsinTransactions = diff.invalidIsins;
        _state.isParsing = false;
      });
    } catch (e) {
      setState(() {
        _state.parsingError = e.toString();
        _state.isParsing = false;
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SAVE TRANSACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _saveTransactions() async {
    if (_state.candidates == null || _state.selectedAccountId == null) return;

    final selectedCandidates =
        _state.candidates!.where((c) => c.selected).toList();
    if (selectedCandidates.isEmpty) return;

    final transactionProvider = context.read<TransactionProvider>();
    final portfolioProvider = context.read<PortfolioProvider>();
    
    final count = await ImportSaveService.saveSelected(
      provider: transactionProvider,
      portfolioProvider: portfolioProvider,
      candidates: selectedCandidates,
      accountId: _state.selectedAccountId!,
      mode: _state.importMode,
      sourceId: _state.selectedSourceId,
      metadataByTicker: _state.crowdfundingMetadata.isEmpty
          ? null
          : _state.crowdfundingMetadata,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count transaction(s) traitée(s) avec succès')),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          WizardHeader(onClose: () => Navigator.pop(context)),
          WizardProgressIndicator(currentStep: _state.currentStep),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildStepContent(),
            ),
          ),
          WizardFooter(
            currentStep: _state.currentStep,
            canProceed: _state.canProceed(),
            onPrevious: _previousStep,
            onNext: _state.canProceed() ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_state.currentStep) {
      case 0:
        return WizardStepFile(
          selectedFile: _state.selectedFile,
          onPickFile: _pickFile,
          onClearFile: _clearFile,
          detectionResult: _state.detectionResult,
          isDetecting: _state.isDetecting,
        );
      case 1:
        return WizardStepSource(
          selectedSourceId: _state.selectedSourceId,
          onSelectSource: (id) {
            setState(() {
              _state.selectedSourceId = id;
            });
          },
          importMode: _state.importMode,
          onImportModeChanged: (mode) {
            setState(() {
              _state.importMode = mode;
            });
          },
          trCategory: _state.selectedTrCategory,
          onTrCategoryChanged: (cat) {
            setState(() {
              _state.selectedTrCategory = cat;
            });
          },
          suggestedSourceId: _state.detectionResult?.sourceId,
          suggestionConfidence: _state.detectionResult?.confidence,
        );
      case 2:
        return WizardValidationStep(
          state: _state,
          onRetryParse: _parseFile,
          onSaveWithWarning: () {
            setState(() {
              _state.hasConfirmedWarnings = true;
            });
            _saveTransactions();
          },
          onAccountChanged: (val) {
            setState(() {
              _state.selectedAccountId = val;
            });
          },
          onCandidateUpdated: (index, updated) {
            setState(() {
              _state.candidates![index] = updated;
            });
          },
          onCandidateDeleted: (index) {
            setState(() {
              _state.candidates!.removeAt(index);
            });
          },
          onWarningConfirmed: (val) {
            setState(() {
              _state.hasConfirmedWarnings = val;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
