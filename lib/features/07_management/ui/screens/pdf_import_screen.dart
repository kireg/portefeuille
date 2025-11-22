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
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/utils/isin_validator.dart';

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
    final tx = _extractedTransactions[index];
    final nameController = TextEditingController(text: tx.assetName);
    final tickerController = TextEditingController(text: tx.ticker);
    final isinController = TextEditingController(text: tx.isin);
    final qtyController = TextEditingController(text: tx.quantity.toString());
    final priceController = TextEditingController(text: tx.price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Modifier la transaction', style: AppTypography.h3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom de l\'actif'),
              ),
              TextField(
                controller: tickerController,
                decoration: const InputDecoration(labelText: 'Ticker (ex: AAPL)'),
              ),
              TextField(
                controller: isinController,
                decoration: const InputDecoration(labelText: 'ISIN (ex: FR0000120073)'),
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Prix unitaire'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _extractedTransactions[index] = ParsedTransaction(
                  date: tx.date,
                  type: tx.type,
                  assetName: nameController.text,
                  ticker: tickerController.text.isEmpty ? null : tickerController.text,
                  isin: isinController.text.isEmpty ? null : isinController.text,
                  quantity: double.tryParse(qtyController.text) ?? tx.quantity,
                  price: double.tryParse(priceController.text) ?? tx.price,
                  amount: (double.tryParse(qtyController.text) ?? tx.quantity) * 
                          (double.tryParse(priceController.text) ?? tx.price),
                  fees: tx.fees,
                  currency: tx.currency,
                );
              });
              Navigator.pop(context);
            },
            child: Text('Enregistrer', style: AppTypography.label.copyWith(color: AppColors.primary)),
          ),
        ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un compte')),
      );
      return;
    }

    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    
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

    int count = 0;

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
        amount: parsed.amount,
        fees: parsed.fees,
        notes: "Import PDF: $_fileName",
        assetType: null, // TODO: Infer asset type
        priceCurrency: parsed.currency,
      );

      await provider.addTransaction(transaction);
      count++;
    }

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
    final existingTransactions = _selectedAccount != null 
        ? provider.activePortfolio?.institutions
            .expand((inst) => inst.accounts)
            .where((acc) => acc.id == _selectedAccount!.id)
            .expand((acc) => acc.transactions)
            .toList() ?? []
        : <Transaction>[];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusL),
      ),
      child: AppScreen(
        withSafeArea: false,
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.paddingL,
                  AppDimens.paddingL,
                  AppDimens.paddingM,
                  AppDimens.paddingM
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Import PDF',
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppIcon(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(),
                      backgroundColor: Colors.transparent,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                children: [
                  // 1. Account Selection
                  FadeInSlide(
                    delay: 0.1,
                    child: AppCard(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Compte de destination", style: AppTypography.h3),
                          const SizedBox(height: AppDimens.paddingS),
                          DropdownButtonFormField<Account>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            value: _selectedAccount,
                            isExpanded: true,
                            items: () {
                              // Group accounts by institution
                              final groupedAccounts = <String, List<Account>>{};
                              for (var acc in accounts) {
                                // Find institution name for this account
                                final inst = provider.activePortfolio?.institutions.firstWhere(
                                  (i) => i.accounts.any((a) => a.id == acc.id),
                                );
                                final instName = inst?.name ?? "Autre";
                                groupedAccounts.putIfAbsent(instName, () => []).add(acc);
                              }

                              final items = <DropdownMenuItem<Account>>[];
                              groupedAccounts.forEach((instName, accs) {
                                // Add Institution Header (disabled)
                                items.add(DropdownMenuItem<Account>(
                                  enabled: false,
                                  child: Text(
                                    instName.toUpperCase(),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ));
                                // Add Accounts
                                for (var acc in accs) {
                                  items.add(DropdownMenuItem<Account>(
                                    value: acc,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 16.0),
                                      child: Text(acc.name, style: AppTypography.body),
                                    ),
                                  ));
                                }
                              });
                              return items;
                            }(),
                            onChanged: (value) {
                              setState(() {
                                _selectedAccount = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppDimens.paddingM),

                  // 2. File Picker
                  FadeInSlide(
                    delay: 0.2,
                    child: AppCard(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Column(
                        children: [
                          if (_fileName == null)
                            AppButton(
                              label: 'Sélectionner un PDF',
                              onPressed: _pickPdf,
                              icon: Icons.upload_file,
                            )
                          else
                            Row(
                              children: [
                                const AppIcon(icon: Icons.description, backgroundColor: AppColors.surfaceLight),
                                const SizedBox(width: AppDimens.paddingS),
                                Expanded(child: Text(_fileName!, style: AppTypography.bodyBold)),
                                IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                                  onPressed: () {
                                    setState(() {
                                      _fileName = null;
                                      _extractedTransactions = [];
                                    });
                                  },
                                )
                              ],
                            ),
                          
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: AppDimens.paddingM),
                              child: LinearProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimens.paddingM),

                  // 3. Preview List
                  if (_extractedTransactions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
                      child: Text("Aperçu (${_extractedTransactions.length})", style: AppTypography.h3),
                    ),
                    ..._extractedTransactions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tx = entry.value;
                      final hasTicker = tx.ticker != null && tx.ticker!.isNotEmpty;
                      final hasIsin = tx.isin != null && IsinValidator.isValidIsinFormat(tx.isin!);
                      final isReady = (hasTicker || hasIsin) && tx.assetName.isNotEmpty;
                      final isDuplicate = _isDuplicate(tx, existingTransactions);

                      return FadeInSlide(
                        delay: 0.3 + (index * 0.05),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              leading: Tooltip(
                                message: isDuplicate 
                                    ? "Doublon détecté" 
                                    : (isReady ? "Prêt à importer" : "ISIN ou Ticker manquant/invalide"),
                                child: AppIcon(
                                  icon: isDuplicate 
                                      ? Icons.copy 
                                      : (isReady ? Icons.check : Icons.warning_amber_rounded),
                                  backgroundColor: isDuplicate 
                                      ? AppColors.error.withOpacity(0.1) 
                                      : (isReady ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1)),
                                  color: isDuplicate 
                                      ? AppColors.error 
                                      : (isReady ? AppColors.success : AppColors.warning),
                                  size: 24,
                                ),
                              ),
                              title: Text(tx.assetName, style: AppTypography.bodyBold),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${tx.type.name} • ${tx.quantity} x ${tx.price} ${tx.currency}',
                                    style: AppTypography.caption,
                                  ),
                                  Text(
                                    '${tx.date.day}/${tx.date.month}/${tx.date.year}${tx.isin != null ? ' • ${tx.isin}' : ''}',
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                  if (isDuplicate)
                                    Text(
                                      "Doublon détecté",
                                      style: AppTypography.caption.copyWith(color: AppColors.error),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.primary),
                                    onPressed: () => _editTransaction(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: AppColors.error),
                                    onPressed: () => _removeTransaction(index),
                                  ),
                                ],
                              ),
                              onTap: () => _editTransaction(index),
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: AppDimens.paddingL),

                    // 4. Validation Button
                    FadeInSlide(
                      delay: 0.5,
                      child: AppButton(
                        label: 'Importer ${_extractedTransactions.length} transactions',
                        onPressed: _validateImport,
                        icon: Icons.check,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
