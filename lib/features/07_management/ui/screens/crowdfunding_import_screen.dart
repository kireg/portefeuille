import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/features/07_management/services/excel/la_premiere_brique_parser.dart';
import 'package:portefeuille/features/07_management/services/excel/parsed_crowdfunding_project.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';
import 'package:portefeuille/features/07_management/ui/widgets/crowdfunding_import/crowdfunding_header.dart';
import 'package:portefeuille/features/07_management/ui/widgets/crowdfunding_import/crowdfunding_account_selector.dart';
import 'package:portefeuille/features/07_management/ui/widgets/crowdfunding_import/crowdfunding_file_picker.dart';
import 'package:portefeuille/features/07_management/ui/widgets/crowdfunding_import/crowdfunding_project_list.dart';
import 'package:portefeuille/features/07_management/ui/widgets/crowdfunding_import/crowdfunding_edit_dialog.dart';

class CrowdfundingImportScreen extends StatefulWidget {
  const CrowdfundingImportScreen({super.key});

  @override
  State<CrowdfundingImportScreen> createState() => _CrowdfundingImportScreenState();
}

class _CrowdfundingImportScreenState extends State<CrowdfundingImportScreen> {
  final _parser = LaPremiereBriqueParser();
  final _uuid = const Uuid();
  
  List<ParsedCrowdfundingProject> _extractedProjects = [];
  String? _loadingStatus; // Remplacé _isLoading par un status textuel
  String? _fileName;
  Account? _selectedAccount;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _loadingStatus = "Lecture du fichier Excel...";
        _fileName = result.files.single.name;
      });

      try {
        final file = File(result.files.single.path!);
        final projects = await _parser.parse(file);

        setState(() {
          _extractedProjects = projects;
          _loadingStatus = null;
        });
      } catch (e) {
        setState(() {
          _loadingStatus = null;
          _fileName = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: $e"), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _editProject(int index) {
    showDialog(
      context: context,
      builder: (context) => CrowdfundingEditDialog(
        project: _extractedProjects[index],
        onSave: (newProject) {
          setState(() {
            _extractedProjects[index] = newProject;
          });
        },
      ),
    );
  }

  void _removeProject(int index) {
    setState(() {
      _extractedProjects.removeAt(index);
    });
  }

  Future<void> _importProjects() async {
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un compte")),
      );
      return;
    }

    setState(() => _loadingStatus = "Préparation de l'import...");
    final provider = context.read<PortfolioProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    int importedCount = 0;
    int skippedCount = 0;

    try {
      // Refresh account to get latest transactions
      final account = provider.portfolios
          .expand((p) => p.institutions)
          .expand((i) => i.accounts)
          .firstWhere((a) => a.id == _selectedAccount!.id, orElse: () => _selectedAccount!);

      final newTransactions = <Transaction>[];
      final newMetadatas = <AssetMetadata>[];

      for (final project in _extractedProjects) {
        // Check for duplicates (Same Name + Same Amount + Same Date)
        // Check in existing account transactions
        final isDuplicateInAccount = account.transactions.any((t) =>
            t.assetName == project.projectName &&
            (t.amount - project.investedAmount).abs() < 0.01 &&
            (project.investmentDate == null || isSameDay(t.date, project.investmentDate!)));
        
        // Check in currently batched transactions
        final isDuplicateInBatch = newTransactions.any((t) =>
            t.assetName == project.projectName &&
            (t.amount - project.investedAmount).abs() < 0.01 &&
            (project.investmentDate == null || isSameDay(t.date, project.investmentDate!)));

        if (isDuplicateInAccount || isDuplicateInBatch) {
          skippedCount++;
          continue;
        }

        // 1. Create Deposit Transaction (Liquidity)
        final depositTransaction = Transaction(
          id: _uuid.v4(),
          accountId: _selectedAccount!.id,
          type: TransactionType.Deposit,
          date: project.investmentDate ?? DateTime.now(),
          amount: project.investedAmount,
          fees: 0.0,
          notes: "Apport auto (Import)",
          assetType: AssetType.Cash,
          priceCurrency: 'EUR',
        );
        newTransactions.add(depositTransaction);

        // 2. Create Buy Transaction
        final transaction = Transaction(
          id: _uuid.v4(),
          accountId: _selectedAccount!.id,
          type: TransactionType.Buy,
          date: project.investmentDate ?? DateTime.now(),
          assetTicker: project.projectName,
          assetName: project.projectName,
          quantity: 1.0,
          price: project.investedAmount,
          amount: -project.investedAmount, // Negative for Buy
          fees: 0.0,
          notes: "Import La Première Brique",
          assetType: AssetType.RealEstateCrowdfunding,
          priceCurrency: 'EUR',
        );

        newTransactions.add(transaction);

        // 2. Create Metadata
        final metadata = AssetMetadata(
          ticker: project.projectName,
          currentPrice: project.investedAmount, // Initial price
          priceCurrency: 'EUR',
          estimatedAnnualYield: project.yieldPercent / 100.0, // Convert % to decimal
          lastUpdated: DateTime.now(),
          isManualYield: true,
          syncStatus: SyncStatus.synced,
          assetTypeDetailed: "Crowdfunding Immobilier",
          projectName: project.projectName,
          location: project.city,
          targetDuration: project.durationMonths,
          minDuration: project.minDurationMonths,
          maxDuration: project.maxDurationMonths,
          expectedYield: project.yieldPercent,
          repaymentType: project.repaymentType,
          riskRating: project.riskRating,
        );
        
        debugPrint("--- DEBUG METADATA: ${project.projectName} ---");
        debugPrint("Target Duration: ${metadata.targetDuration}");
        debugPrint("Min Duration: ${metadata.minDuration}");
        debugPrint("Max Duration: ${metadata.maxDuration}");

        newMetadatas.add(metadata);
        importedCount++;
      }

      // 3. Batch Save
      if (newMetadatas.isNotEmpty) {
        setState(() => _loadingStatus = "Mise à jour des métadonnées...");
        await provider.updateAssetMetadatas(newMetadatas);
      }

      if (newTransactions.isNotEmpty) {
        setState(() => _loadingStatus = "Sauvegarde des transactions...");
        await transactionProvider.addTransactions(newTransactions);
      }

      if (mounted) {
        final msg = skippedCount > 0
            ? "$importedCount projets importés ($skippedCount doublons ignorés)"
            : "$importedCount projets importés avec succès";
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'import: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingStatus = null);
    }
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusL),
      ),
      child: AppScreen(
        withSafeArea: false,
        body: Column(
          children: [
            // Header
            const CrowdfundingHeader(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                children: [
                  // 1. Account Selection
                  CrowdfundingAccountSelector(
                    selectedAccount: _selectedAccount,
                    onChanged: (val) => setState(() => _selectedAccount = val),
                  ),

                  const SizedBox(height: AppDimens.paddingM),

                  // 2. File Picker
                  CrowdfundingFilePicker(
                    fileName: _fileName,
                    onPickFile: _pickFile,
                    onClearFile: () => setState(() {
                      _fileName = null;
                      _extractedProjects = [];
                    }),
                  ),

                  const SizedBox(height: AppDimens.paddingM),

                  // List of Projects
                  CrowdfundingProjectList(
                    projects: _extractedProjects,
                    selectedAccount: _selectedAccount,
                    onEdit: _editProject,
                    onRemove: _removeProject,
                    loadingStatus: _loadingStatus,
                  ),
                ],
              ),
            ),

            // Bottom Action Bar
            if (_extractedProjects.isNotEmpty && _loadingStatus == null)
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
                    label: "Importer ${_extractedProjects.length} projets",
                    icon: Icons.download_rounded,
                    onPressed: _importProjects,
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
