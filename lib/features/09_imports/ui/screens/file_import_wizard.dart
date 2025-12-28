import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import 'package:excel/excel.dart' as excel_lib hide Border;
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_dropdown.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/boursorama_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_account_statement_parser.dart';
import 'package:portefeuille/features/09_imports/services/csv/parsers/revolut_parser.dart';
import 'package:portefeuille/features/09_imports/services/excel/la_premiere_brique_parser.dart';
import 'package:portefeuille/features/09_imports/services/models/import_category.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';
import 'package:portefeuille/features/09_imports/services/source_detector.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/features/09_imports/ui/widgets/wizard_step_file.dart';
import 'package:portefeuille/features/09_imports/ui/widgets/wizard_step_source.dart';
import 'package:portefeuille/features/09_imports/ui/screens/ai_import_config_screen.dart';
import 'package:portefeuille/features/09_imports/ui/widgets/transaction_edit_dialog.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/services/import_save_service.dart';
import 'package:portefeuille/features/09_imports/i18n/strings.dart';

class FileImportWizard extends StatefulWidget {
  const FileImportWizard({super.key});

  @override
  State<FileImportWizard> createState() => _FileImportWizardState();
}

class _FileImportWizardState extends State<FileImportWizard> {
  int _currentStep = 0;
  PlatformFile? _selectedFile;
  String? _selectedSourceId;
  ImportMode _importMode = ImportMode.initial;
  ImportCategory _selectedTrCategory = ImportCategory.cto;
  Map<String, AssetMetadata> _crowdfundingMetadata = {};

  // Source detection
  final SourceDetector _sourceDetector = SourceDetector();
  SourceDetectionResult? _detectionResult;
  bool _isDetecting = false;

  // Step 3: Validation & Parsing
  bool _isParsing = false;
  double _parsingProgress = 0.0; // New state for progress
  String? _parsingError;
  String? _parserWarning; // New state variable
  List<ImportCandidate>? _candidates;
  String? _selectedAccountId;

  // Validation Warnings
  List<ParsedTransaction> _duplicateTransactions = [];
  List<ParsedTransaction> _invalidIsinTransactions = [];
  bool _hasConfirmedWarnings = false;

  // La logique de clés/diff est gérée par ImportDiffService.

  Widget _buildCandidateCard(int index, ImportCandidate candidate) {
    final tx = candidate.parsed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: candidate.selected,
              onChanged: (val) {
                setState(() {
                  candidate.selected = val ?? false;
                });
              },
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (tx.type == TransactionType.Buy ||
                        tx.type == TransactionType.Deposit)
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                (tx.type == TransactionType.Buy ||
                        tx.type == TransactionType.Deposit)
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: (tx.type == TransactionType.Buy ||
                        tx.type == TransactionType.Deposit)
                    ? AppColors.success
                    : AppColors.error,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tx.assetName,
                          style: AppTypography.bodyBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (candidate.isModified)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Modifié",
                            style: AppTypography.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    "${tx.date.day}/${tx.date.month}/${tx.date.year} • ${tx.type.toString().split('.').last}",
                    style: AppTypography.caption,
                  ),
                  if (tx.isin != null)
                    Text(
                      "ISIN: ${tx.isin}",
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${tx.amount.toStringAsFixed(2)} ${tx.currency}",
                  style: AppTypography.bodyBold,
                ),
                Text(
                  "${tx.quantity} @ ${tx.price.toStringAsFixed(2)}",
                  style: AppTypography.caption,
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'edit') {
                  showDialog(
                    context: context,
                    builder: (context) => TransactionEditDialog(
                      transaction: tx,
                      onSave: (updated) {
                        setState(() {
                          _candidates![index] =
                              candidate.copyWith(parsed: updated);
                        });
                      },
                    ),
                  );
                } else if (value == 'delete') {
                  setState(() {
                    _candidates!.removeAt(index);
                  });
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 8),
                      Text("Modifier"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text("Supprimer",
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helpers supprimés au profit d'ImportDiffService.

  // Step 1: File Selection
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'xlsx', 'xls'],
        withData:
            true, // Important for web/some platforms to get bytes immediately if needed
      );

      if (result != null) {
        final file = result.files.single;
        setState(() {
          _selectedFile = file;
          _detectionResult = null;
          _isDetecting = true;
        });

        // Lancer la détection automatique
        await _detectSource(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection : $e')),
      );
    }
  }

  Future<void> _detectSource(PlatformFile file) async {
    try {
      final detection = await _sourceDetector.detect(file);
      if (mounted) {
        setState(() {
          _detectionResult = detection;
          _isDetecting = false;
          // Auto-sélection si haute confiance
          if (detection.isDetected && detection.sourceId != null) {
            _selectedSourceId = detection.sourceId;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
          _detectionResult = SourceDetectionResult(
            message: 'Erreur lors de la détection: $e',
          );
        });
      }
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
      _detectionResult = null;
      _selectedSourceId = null;
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

      if (_currentStep == 2) {
        _parseFile();
      }
    } else if (_currentStep == 2) {
      _saveTransactions();
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

  Future<void> _parseFile() async {
    if (_selectedFile == null || _selectedSourceId == null) return;

    setState(() {
      _isParsing = true;
      _parsingProgress = 0.0;
      _parsingError = null;
      _parserWarning = null;
      _candidates = null;
      _duplicateTransactions = [];
      _invalidIsinTransactions = [];
      _hasConfirmedWarnings = false;
      _crowdfundingMetadata = {};
    });

    try {
      final file = _selectedFile!;
      final sourceId = _selectedSourceId!;
      List<ParsedTransaction> results = [];

      if (sourceId == 'la_premiere_brique') {
        final parser = LaPremiereBriqueParser();
        final projects = await parser.parse(file);
        _crowdfundingMetadata = {};

        // Convert to ParsedTransaction + préparer les métadonnées Crowdfunding
        // Note: Le montant est négatif pour les achats (convention de l'app)
        // Un dépôt compensatoire sera créé par ImportSaveService pour neutraliser l'impact sur les liquidités
        results = projects.map((p) {
          final ticker = p.projectName;

          _crowdfundingMetadata[ticker] = AssetMetadata(
            ticker: ticker,
            projectName: p.projectName,
            minDuration: p.minDurationMonths,
            targetDuration: p.durationMonths,
            maxDuration: p.maxDurationMonths,
            expectedYield: p.yieldPercent,
            repaymentType: p.repaymentType,
            priceCurrency: 'EUR',
          );

          return ParsedTransaction(
            date: p.investmentDate ?? DateTime.now(),
            type: TransactionType.Buy,
            assetName: p.projectName,
            ticker: ticker,
            quantity: p.investedAmount,
            price: 1.0,
            amount: -p.investedAmount, // Négatif pour un achat (convention de l'app)
            fees: 0,
            currency: 'EUR',
            assetType: AssetType.RealEstateCrowdfunding,
          );
        }).toList();
      } else {
        // Text based parsers
        String text = await _extractText(file);
        StatementParser? parser;

        switch (sourceId) {
          case 'boursorama':
            parser = BoursoramaParser();
            break;
          case 'revolut':
            parser = RevolutParser();
            break;
          case 'trade_republic':
            final trSnapshotParser = TradeRepublicParser();
            final trStatementParser = TradeRepublicAccountStatementParser();

            if (trStatementParser.canParse(text)) {
              parser = trStatementParser;
            } else {
              parser = trSnapshotParser;
            }
            break;
        }

        if (parser != null) {
          _parserWarning = parser.warningMessage;
          results = await parser.parse(text, onProgress: (progress) {
            if (mounted) {
              setState(() {
                _parsingProgress = progress;
              });
            }
          });

          // Filtrage par catégorie Trade Republic si applicable
          if (sourceId == 'trade_republic') {
            results = results
                .where((p) =>
                    p.category == null || p.category == _selectedTrCategory)
                .toList();
          }
        }
      }

      // --- VALIDATION LOGIC ---
      final portfolioProvider = context.read<PortfolioProvider>();
      final activePortfolio = portfolioProvider.activePortfolio;
      final List<Transaction> existingTransactions = [];
      if (activePortfolio != null) {
        for (var inst in activePortfolio.institutions) {
          for (var acc in inst.accounts) {
            existingTransactions.addAll(acc.transactions);
          }
        }
      }

      final diff = ImportDiffService().compute(
        parsed: results,
        existing: existingTransactions,
        mode: _importMode,
      );

      setState(() {
        _candidates = diff.candidates;
        _duplicateTransactions = diff.duplicates;
        _invalidIsinTransactions = diff.invalidIsins;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _parsingError = e.toString();
        _isParsing = false;
      });
    }
  }

  Future<String> _extractText(PlatformFile file) async {
    final extension = file.extension?.toLowerCase();

    if (extension == 'pdf') {
      final PdfDocument document = PdfDocument(
          inputBytes: file.bytes ?? await File(file.path!).readAsBytes());
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    }

    final bytes = file.bytes ?? await File(file.path!).readAsBytes();

    if (extension == 'xlsx' || extension == 'xls') {
      try {
        final excel = excel_lib.Excel.decodeBytes(bytes);
        if (excel.tables.isEmpty) return '';

        final buffer = StringBuffer();
        final sheet = excel.tables.values.first;

        for (final row in sheet.rows) {
          final cells = row.map(_stringifyCell).toList();
          if (cells.every((value) => value.trim().isEmpty)) continue;
          buffer.writeln(cells.join(','));
        }

        return buffer.toString();
      } on FormatException {
        // Fallback: fichier corrompu ou non Excel malgré l'extension, on tente un décodage texte simple
        return utf8.decode(bytes, allowMalformed: true);
      }
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  String _stringifyCell(excel_lib.Data? cell) {
    final value = cell?.value;
    if (value == null) return '';

    if (value is excel_lib.TextCellValue) return value.value.toString();
    if (value is excel_lib.DateCellValue) {
      return DateTime(value.year, value.month, value.day).toIso8601String();
    }

    return value.toString();
  }

  Future<void> _saveTransactions() async {
    if (_candidates == null || _selectedAccountId == null) return;

    final selectedCandidates = _candidates!.where((c) => c.selected).toList();
    if (selectedCandidates.isEmpty) return;

    final transactionProvider = context.read<TransactionProvider>();
    final portfolioProvider = context.read<PortfolioProvider>();
    final count = await ImportSaveService.saveSelected(
      provider: transactionProvider,
      portfolioProvider: portfolioProvider,
      candidates: selectedCandidates,
      accountId: _selectedAccountId!,
      mode: _importMode,
      sourceId: _selectedSourceId,
      metadataByTicker: _crowdfundingMetadata.isEmpty ? null : _crowdfundingMetadata,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
              Text('$count transaction(s) traitée(s) avec succès')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height *
          0.85, // 85% height for bottom sheet
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
          color: isActive
              ? AppColors.primary
              : AppColors.textSecondary.withValues(alpha: 0.3),
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
          detectionResult: _detectionResult,
          isDetecting: _isDetecting,
        );
      case 1:
        return WizardStepSource(
          selectedSourceId: _selectedSourceId,
          onSelectSource: (id) {
            setState(() {
              _selectedSourceId = id;
            });
          },
          importMode: _importMode,
          onImportModeChanged: (mode) {
            setState(() {
              _importMode = mode;
            });
          },
          trCategory: _selectedTrCategory,
          onTrCategoryChanged: (cat) {
            setState(() {
              _selectedTrCategory = cat;
            });
          },
          suggestedSourceId: _detectionResult?.sourceId,
          suggestionConfidence: _detectionResult?.confidence,
        );
      case 2:
        return _buildValidationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildValidationStep() {
    if (_isParsing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text("Analyse du fichier en cours..."),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _parsingProgress,
                backgroundColor: AppColors.surfaceLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 4),
            Text("${(_parsingProgress * 100).toInt()}%"),
          ],
        ),
      );
    }

    if (_parsingError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              "Erreur lors de l'analyse",
              style: AppTypography.h3.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(_parsingError!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            AppButton(
              label: "Réessayer",
              onPressed: _parseFile,
              type: AppButtonType.secondary,
            ),
          ],
        ),
      );
    }

    if (_parserWarning != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 48),
            const SizedBox(height: 16),
            Text(
              StringsImport.warningTitle,
              style: AppTypography.h3.copyWith(color: AppColors.warning),
            ),
            const SizedBox(height: 8),
            Text(_parserWarning!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            AppButton(
              label: StringsImport.continueDespiteWarning,
              onPressed: () {
                setState(() {
                  _hasConfirmedWarnings = true;
                });
                _saveTransactions();
              },
              type: AppButtonType.secondary,
            ),
          ],
        ),
      );
    }

    if (_candidates == null || _candidates!.isEmpty) {
      return const Center(child: Text(StringsImport.noneFound));
    }

    // Account Selection
    final portfolioProvider = context.watch<PortfolioProvider>();
    final activePortfolio = portfolioProvider.activePortfolio;
    final List<DropdownMenuItem<String>> accountItems = [];
    if (activePortfolio != null) {
      for (final institution in activePortfolio.institutions) {
        for (final account in institution.accounts) {
          accountItems.add(
            DropdownMenuItem(
              value: account.id,
              child: Text("${institution.name} - ${account.name}"),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_parserWarning != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _parserWarning!,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
        Text(StringsImport.validationTitle, style: AppTypography.h2),
        const SizedBox(height: 8),
        Text(
          "${_candidates!.length} transactions retenues (${_candidates!.where((c) => c.isModified).length} modifiées)",
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // --- WARNINGS SECTION ---
        if (_duplicateTransactions.isNotEmpty ||
            _invalidIsinTransactions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(StringsImport.attentionRequired,
                        style: AppTypography.h3
                            .copyWith(color: AppColors.warning)),
                  ],
                ),
                const SizedBox(height: 8),
                if (_duplicateTransactions.isNotEmpty)
                  Text(
                    "• ${_duplicateTransactions.length} doublons potentiels détectés (même date, quantité, montant).",
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary),
                  ),
                if (_invalidIsinTransactions.isNotEmpty)
                  Text(
                    "• ${_invalidIsinTransactions.length} codes ISIN semblent invalides.",
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _hasConfirmedWarnings,
                      activeColor: AppColors.warning,
                      onChanged: (val) {
                        setState(() {
                          _hasConfirmedWarnings = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        "Je confirme vouloir importer ces transactions malgré les avertissements.",
                        style: AppTypography.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // --- END WARNINGS SECTION ---

        AppDropdown<String>(
          label: StringsImport.destinationAccount,
          value: _selectedAccountId,
          items: accountItems,
          onChanged: (val) => setState(() => _selectedAccountId = val),
        ),

        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              // Nouveaux
              if (_candidates!.any((c) => !c.isModified)) ...[
                Text(
                  "${StringsImport.newLabel} (${_candidates!.where((c) => !c.isModified).length})",
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 8),
                ..._candidates!
                    .asMap()
                    .entries
                    .where((e) => !e.value.isModified)
                    .map((entry) => _buildCandidateCard(entry.key, entry.value))
                    .toList(),
                const SizedBox(height: 16),
              ],
              // Modifiés
              if (_candidates!.any((c) => c.isModified)) ...[
                Text(
                  "${StringsImport.modifiedLabel} (${_candidates!.where((c) => c.isModified).length})",
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 8),
                ..._candidates!
                    .asMap()
                    .entries
                    .where((e) => e.value.isModified)
                    .map((entry) => _buildCandidateCard(entry.key, entry.value))
                    .toList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    bool canGoNext = false;
    if (_currentStep == 0 && _selectedFile != null) canGoNext = true;
    if (_currentStep == 1 && _selectedSourceId != null) canGoNext = true;
    if (_currentStep == 2 &&
        _selectedAccountId != null &&
        _candidates != null &&
        _candidates!.any((c) => c.selected)) {
      if (_duplicateTransactions.isNotEmpty ||
          _invalidIsinTransactions.isNotEmpty) {
        canGoNext = _hasConfirmedWarnings;
      } else {
        canGoNext = true;
      }
    }

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
