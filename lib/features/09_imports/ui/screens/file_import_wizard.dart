import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_dropdown.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/boursorama_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_parser.dart';
import 'package:portefeuille/features/09_imports/services/csv/parsers/revolut_parser.dart';
import 'package:portefeuille/features/09_imports/services/excel/la_premiere_brique_parser.dart';
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

  // Step 3: Validation & Parsing
  bool _isParsing = false;
  String? _parsingError;
  List<ParsedTransaction>? _parsedTransactions;
  String? _selectedAccountId;

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
      _parsingError = null;
      _parsedTransactions = null;
    });

    try {
      final file = _selectedFile!;
      final sourceId = _selectedSourceId!;
      List<ParsedTransaction> results = [];

      if (sourceId == 'la_premiere_brique') {
         final parser = LaPremiereBriqueParser();
         final projects = await parser.parse(file);
         // Convert to ParsedTransaction
         results = projects.map((p) => ParsedTransaction(
            date: p.investmentDate ?? DateTime.now(),
            type: TransactionType.Buy,
            assetName: p.projectName,
            quantity: p.investedAmount, 
            price: 1.0,
            amount: p.investedAmount,
            fees: 0,
            currency: 'EUR',
            assetType: AssetType.RealEstateCrowdfunding,
         )).toList();
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
             parser = TradeRepublicParser();
             break;
         }
         
         if (parser != null) {
           results = parser.parse(text);
         }
      }

      setState(() {
        _parsedTransactions = results;
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
    if (file.extension?.toLowerCase() == 'pdf') {
       final PdfDocument document = PdfDocument(inputBytes: file.bytes ?? await File(file.path!).readAsBytes());
       String text = PdfTextExtractor(document).extractText();
       document.dispose();
       return text;
    } else {
       final bytes = file.bytes ?? await File(file.path!).readAsBytes();
       return utf8.decode(bytes);
    }
  }

  Future<void> _saveTransactions() async {
    if (_parsedTransactions == null || _selectedAccountId == null) return;

    final portfolioProvider = context.read<PortfolioProvider>();
    
    for (final parsed in _parsedTransactions!) {
      final transaction = Transaction(
        id: const Uuid().v4(),
        accountId: _selectedAccountId!,
        type: parsed.type,
        date: parsed.date,
        assetTicker: parsed.ticker,
        assetName: parsed.assetName,
        quantity: parsed.quantity,
        price: parsed.price,
        amount: parsed.amount,
        fees: parsed.fees,
        notes: "Importé depuis ${_selectedSourceId}",
        assetType: parsed.assetType,
        priceCurrency: parsed.currency,
      );
      
      await portfolioProvider.addTransaction(transaction);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_parsedTransactions!.length} transactions importées avec succès')),
      );
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
        return _buildValidationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildValidationStep() {
    if (_isParsing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Analyse du fichier en cours..."),
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

    if (_parsedTransactions == null || _parsedTransactions!.isEmpty) {
      return const Center(child: Text("Aucune transaction trouvée."));
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
        Text("Validation", style: AppTypography.h2),
        const SizedBox(height: 8),
        Text(
          "${_parsedTransactions!.length} transactions trouvées.",
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        
        AppDropdown<String>(
          label: "Compte de destination",
          value: _selectedAccountId,
          items: accountItems,
          onChanged: (val) => setState(() => _selectedAccountId = val),
          hint: "Sélectionner un compte",
        ),
        
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _parsedTransactions!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = _parsedTransactions![index];
              return AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (tx.type == TransactionType.Buy || tx.type == TransactionType.Deposit) 
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (tx.type == TransactionType.Buy || tx.type == TransactionType.Deposit) 
                            ? Icons.arrow_downward 
                            : Icons.arrow_upward,
                        color: (tx.type == TransactionType.Buy || tx.type == TransactionType.Deposit) 
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
                          Text(tx.assetName, style: AppTypography.bodyBold),
                          Text(
                            "${tx.date.day}/${tx.date.month}/${tx.date.year}",
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${tx.amount.toStringAsFixed(2)} ${tx.currency}",
                      style: AppTypography.bodyBold,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    bool canGoNext = false;
    if (_currentStep == 0 && _selectedFile != null) canGoNext = true;
    if (_currentStep == 1 && _selectedSourceId != null) canGoNext = true;
    if (_currentStep == 2 && _selectedAccountId != null && _parsedTransactions != null && _parsedTransactions!.isNotEmpty) canGoNext = true;

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
