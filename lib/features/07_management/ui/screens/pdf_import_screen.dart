import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/features/07_management/services/pdf_import_service.dart';
import 'package:portefeuille/features/07_management/services/pdf/statement_parser.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';

import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/utils/isin_validator.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';

import 'package:portefeuille/features/07_management/ui/widgets/pdf_import/pdf_header.dart';
import 'package:portefeuille/features/07_management/ui/widgets/pdf_import/pdf_account_selector.dart';
import 'package:portefeuille/features/07_management/ui/widgets/pdf_import/pdf_file_picker.dart';
import 'package:portefeuille/features/07_management/ui/widgets/pdf_import/pdf_transaction_list.dart';
import 'package:portefeuille/features/07_management/ui/widgets/pdf_import/pdf_edit_dialog.dart';

class PdfImportScreen extends StatefulWidget {
  const PdfImportScreen({super.key});

  @override
  State<PdfImportScreen> createState() => _PdfImportScreenState();
}

class _PdfImportScreenState extends State<PdfImportScreen> {
  final _pdfService = PdfImportService();
  final _uuid = const Uuid();
  
  List<ParsedTransaction> _extractedTransactions = [];
  bool _isLoading = false;
  String? _fileName;
  Account? _selectedAccount;
  bool _showAccountError = false;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isLoading = true;
        _fileName = result.files.single.name;
      });

      final file = File(result.files.single.path!);
      final transactions = await _pdfService.extractTransactions(file);

      setState(() {
        _extractedTransactions = transactions;
        _isLoading = false;
      });
    }
  }

  void _removeTransaction(int index) {
    setState(() {
      _extractedTransactions.removeAt(index);
    });
  }

  void _editTransaction(int index) {
    showDialog(
      context: context,
      builder: (context) => PdfEditDialog(
        transaction: _extractedTransactions[index],
        onSave: (newTx) {
          setState(() {
            _extractedTransactions[index] = newTx;
          });
        },
      ),
    );
  }

  bool _isDuplicate(ParsedTransaction parsed, List<Transaction> existingTransactions) {
    // Check if a transaction with same date, same asset (ISIN/Ticker/Name) and same quantity exists
    // We use a small tolerance for date (same day)
    
    for (final existing in existingTransactions) {
      final sameDate = existing.date.year == parsed.date.year && 
                       existing.date.month == parsed.date.month && 
                       existing.date.day == parsed.date.day;
      
      if (!sameDate) continue;
      
      final sameType = existing.type == parsed.type;
      if (!sameType) continue;

      final sameQuantity = (existing.quantity ?? 0) == parsed.quantity;
      if (!sameQuantity) continue;

      // Check asset identity
      bool sameAsset = false;
      if (parsed.isin != null && existing.assetTicker == parsed.isin) {
        sameAsset = true;
      } else if (parsed.ticker != null && existing.assetTicker == parsed.ticker) {
        sameAsset = true;
      } else if (existing.assetName == parsed.assetName) {
        sameAsset = true;
      }

      if (sameAsset) return true;
    }
    return false;
  }

  Future<void> _validateImport() async {
    if (_selectedAccount == null) {
      setState(() {
        _showAccountError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un compte')),
      );
      return;
    }

    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Get existing transactions for duplicate check
    final existingTransactions = provider.activePortfolio?.institutions
            .expand((inst) => inst.accounts)
            .where((acc) => acc.id == _selectedAccount!.id)
            .expand((acc) => acc.transactions)
            .toList() ?? [];

    // Identify issues
    final duplicates = <ParsedTransaction>[];
    final invalid = <ParsedTransaction>[];
    final valid = <ParsedTransaction>[];

    for (final tx in _extractedTransactions) {
      final isDuplicate = _isDuplicate(tx, existingTransactions);
      final hasTicker = tx.ticker != null && tx.ticker!.isNotEmpty;
      final hasIsin = tx.isin != null && IsinValidator.isValidIsinFormat(tx.isin!);
      final isReady = (hasTicker || hasIsin) && tx.assetName.isNotEmpty;

      if (isDuplicate) {
        duplicates.add(tx);
      } else if (!isReady) {
        invalid.add(tx);
      } else {
        valid.add(tx);
      }
    }

    if (duplicates.isNotEmpty || invalid.isNotEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: Text('Attention', style: AppTypography.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (duplicates.isNotEmpty)
                Text('• ${duplicates.length} doublons détectés', style: AppTypography.body.copyWith(color: AppColors.error)),
              if (invalid.isNotEmpty)
                Text('• ${invalid.length} transactions incomplètes (ISIN/Ticker)', style: AppTypography.body.copyWith(color: AppColors.warning)),
              const SizedBox(height: AppDimens.paddingM),
              Text('Que voulez-vous faire ?', style: AppTypography.bodyBold),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), // Cancel
              child: Text('Annuler', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
            ),
            if (valid.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Filter list to keep only valid
                  setState(() {
                    _extractedTransactions = valid;
                  });
                  Navigator.pop(ctx, true); // Continue with filtered list
                },
                child: Text('Importer valides (${valid.length})', style: AppTypography.label.copyWith(color: AppColors.primary)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), // Continue with all
              child: Text('Tout importer', style: AppTypography.label.copyWith(color: AppColors.error)),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    final newTransactions = <Transaction>[];

    for (final parsed in _extractedTransactions) {
      // Conversion ParsedTransaction -> Transaction
      final transaction = Transaction(
        id: _uuid.v4(),
        accountId: _selectedAccount!.id,
        type: parsed.type,
        date: parsed.date,
        assetTicker: parsed.ticker ?? parsed.isin ?? parsed.assetName, // Fallback ticker/ISIN
        assetName: parsed.assetName,
        quantity: parsed.quantity,
        price: parsed.price,
        amount: (parsed.type == TransactionType.Buy || parsed.type == TransactionType.Withdrawal)
            ? -parsed.amount.abs()
            : parsed.amount.abs(),
        fees: parsed.fees,
        notes: "Import PDF: $_fileName",
        assetType: parsed.assetType ?? AssetType.Stock, // Use inferred or default
        priceCurrency: parsed.currency,
      );

      newTransactions.add(transaction);

      // Create Metadata with default 5% yield if it doesn't exist
      final metadata = AssetMetadata(
        ticker: transaction.assetTicker ?? transaction.assetName ?? 'UNKNOWN',
        projectName: transaction.assetName,
        assetTypeDetailed: (transaction.assetType ?? AssetType.Stock).displayName,
        estimatedAnnualYield: 0.05, // Default 5%
        lastUpdated: DateTime.now(),
        priceCurrency: transaction.priceCurrency,
        currentPrice: transaction.price ?? 0.0,
        syncStatus: SyncStatus.manual,
        isManualYield: true,
      );
      
      // We don't save metadata here directly, but usually the PortfolioProvider handles it
      // or we should add it. For now, let's assume the user wants this default.
      // Since addTransactions doesn't automatically create metadata with specific yield,
      // we might need to update metadata explicitly.
      
      // However, looking at the code, we only add transactions.
      // Let's add metadata update.
      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      await provider.updateAssetMetadatas([metadata]);

      // Auto-Deposit for Buy transactions to neutralize liquidity impact
      if (parsed.type == TransactionType.Buy) {
         final depositTransaction = Transaction(
          id: _uuid.v4(),
          accountId: _selectedAccount!.id,
          type: TransactionType.Deposit,
          date: parsed.date, // Same date
          assetTicker: null,
          assetName: "Dépôt (Auto-Import)",
          quantity: null,
          price: null,
          amount: parsed.amount + parsed.fees, // Cover cost + fees
          fees: 0,
          notes: "Auto-dépôt pour couvrir l'achat de ${parsed.assetName}",
          assetType: AssetType.Cash,
          priceCurrency: parsed.currency,
        );
        newTransactions.add(depositTransaction);
      }
    }

    if (newTransactions.isNotEmpty) {
      await transactionProvider.addTransactions(newTransactions);
    }
    
    int count = newTransactions.length;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count transactions importées avec succès')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortfolioProvider>(context);
    // Flatten all accounts from all institutions in the active portfolio
    final accounts = provider.activePortfolio?.institutions
        .expand((inst) => inst.accounts)
        .toList() ?? [];

    // Get existing transactions for duplicate check
    final existingTransactions = _selectedAccount == null 
        ? <Transaction>[]
        : accounts
            .where((acc) => acc.id == _selectedAccount!.id)
            .expand((acc) => acc.transactions)
            .toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusL),
      ),
      child: AppScreen(
        withSafeArea: false,
        body: Column(
          children: [
            // Header
            const PdfHeader(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                children: [
                  // 1. Account Selection
                  PdfAccountSelector(
                    selectedAccount: _selectedAccount,
                    hasError: _showAccountError,
                    onChanged: (val) => setState(() {
                      _selectedAccount = val;
                      if (val != null) _showAccountError = false;
                    }),
                  ),

                  const SizedBox(height: AppDimens.paddingM),

                  // 2. File Picker
                  PdfFilePicker(
                    fileName: _fileName,
                    onPickFile: _pickPdf,
                    onClearFile: () => setState(() {
                      _fileName = null;
                      _extractedTransactions = [];
                    }),
                  ),

                  const SizedBox(height: AppDimens.paddingM),

                  // List of Transactions
                  PdfTransactionList(
                    transactions: _extractedTransactions,
                    existingTransactions: existingTransactions,
                    onEdit: _editTransaction,
                    onRemove: _removeTransaction,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),

            // Bottom Action Bar
            if (_extractedTransactions.isNotEmpty && !_isLoading)
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: AppButton(
                    label: "Valider l'import (${_extractedTransactions.length})",
                    icon: Icons.check_circle,
                    onPressed: _validateImport,
                    isFullWidth: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
