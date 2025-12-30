import 'package:file_picker/file_picker.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/features/09_imports/services/models/import_category.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';
import 'package:portefeuille/features/09_imports/services/source_detector.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

/// État centralisé du wizard d'import.
/// 
/// Contient toutes les variables d'état pour les 3 étapes du wizard :
/// - Étape 0 : Sélection de fichier
/// - Étape 1 : Sélection de source
/// - Étape 2 : Validation et import
class WizardState {
  // Navigation
  int currentStep = 0;

  // Step 0: File Selection
  PlatformFile? selectedFile;
  SourceDetectionResult? detectionResult;
  bool isDetecting = false;

  // Step 1: Source Selection
  String? selectedSourceId;
  ImportMode importMode = ImportMode.initial;
  ImportCategory selectedTrCategory = ImportCategory.cto;

  // Step 2: Validation & Parsing
  bool isParsing = false;
  double parsingProgress = 0.0;
  String? parsingError;
  String? parserWarning;
  List<ImportCandidate>? candidates;
  String? selectedAccountId;

  // Validation Warnings
  List<ParsedTransaction> duplicateTransactions = [];
  List<ParsedTransaction> invalidIsinTransactions = [];
  bool hasConfirmedWarnings = false;

  // Crowdfunding metadata
  Map<String, AssetMetadata> crowdfundingMetadata = {};

  /// Réinitialise l'état pour une nouvelle sélection de fichier.
  void resetForNewFile() {
    selectedFile = null;
    detectionResult = null;
    isDetecting = false;
    selectedSourceId = null;
    _resetParsingState();
  }

  /// Réinitialise l'état de parsing.
  void _resetParsingState() {
    isParsing = false;
    parsingProgress = 0.0;
    parsingError = null;
    parserWarning = null;
    candidates = null;
    duplicateTransactions = [];
    invalidIsinTransactions = [];
    hasConfirmedWarnings = false;
    crowdfundingMetadata = {};
  }

  /// Prépare l'état pour le parsing.
  void prepareForParsing() {
    isParsing = true;
    parsingProgress = 0.0;
    parsingError = null;
    parserWarning = null;
    candidates = null;
    duplicateTransactions = [];
    invalidIsinTransactions = [];
    hasConfirmedWarnings = false;
    crowdfundingMetadata = {};
  }

  /// Vérifie si on peut passer à l'étape suivante.
  bool canProceed() {
    switch (currentStep) {
      case 0:
        return selectedFile != null;
      case 1:
        return selectedSourceId != null;
      case 2:
        if (selectedAccountId == null) return false;
        if (candidates == null || !candidates!.any((c) => c.selected)) {
          return false;
        }
        if (duplicateTransactions.isNotEmpty ||
            invalidIsinTransactions.isNotEmpty) {
          return hasConfirmedWarnings;
        }
        return true;
      default:
        return false;
    }
  }
}
