import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:portefeuille/features/07_management/services/excel/la_premiere_brique_parser.dart';
import 'package:portefeuille/features/07_management/services/excel/parsed_crowdfunding_project.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/data/models/repayment_type.dart';

class CrowdfundingImportScreen extends StatefulWidget {
  const CrowdfundingImportScreen({super.key});

  @override
  State<CrowdfundingImportScreen> createState() => _CrowdfundingImportScreenState();
}

class _CrowdfundingImportScreenState extends State<CrowdfundingImportScreen> {
  final _parser = LaPremiereBriqueParser();
  final _uuid = const Uuid();
  
  List<ParsedCrowdfundingProject> _extractedProjects = [];
  bool _isLoading = false;
  String? _fileName;
  Account? _selectedAccount;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isLoading = true;
        _fileName = result.files.single.name;
      });

      try {
        final file = File(result.files.single.path!);
        final projects = await _parser.parse(file);

        setState(() {
          _extractedProjects = projects;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
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
    final project = _extractedProjects[index];
    final nameController = TextEditingController(text: project.projectName);
    final amountController = TextEditingController(text: project.investedAmount.toString());
    final yieldController = TextEditingController(text: project.yieldPercent.toString());
    final minDurationController = TextEditingController(text: (project.minDurationMonths ?? project.durationMonths).toString());
    final targetDurationController = TextEditingController(text: project.durationMonths.toString());
    final maxDurationController = TextEditingController(text: (project.maxDurationMonths ?? project.durationMonths).toString());
    final cityController = TextEditingController(text: project.city ?? '');
    
    RepaymentType selectedRepayment = project.repaymentType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Modifier le projet', style: AppTypography.h3),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom du projet'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Montant (€)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: yieldController,
                      decoration: const InputDecoration(labelText: 'Rendement (%)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minDurationController,
                      decoration: const InputDecoration(labelText: 'Durée Min (mois)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: targetDurationController,
                      decoration: const InputDecoration(labelText: 'Durée Cible (mois)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: maxDurationController,
                      decoration: const InputDecoration(labelText: 'Durée Max (mois)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<RepaymentType>(
                value: selectedRepayment,
                decoration: const InputDecoration(labelText: 'Remboursement'),
                items: RepaymentType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.displayName),
                )).toList(),
                onChanged: (val) {
                  if (val != null) selectedRepayment = val;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
            ],
          ),
        ),
      ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _extractedProjects[index] = ParsedCrowdfundingProject(
                  projectName: nameController.text,
                  platform: project.platform,
                  investmentDate: project.investmentDate,
                  investedAmount: double.tryParse(amountController.text) ?? project.investedAmount,
                  yieldPercent: double.tryParse(yieldController.text) ?? project.yieldPercent,
                  durationMonths: int.tryParse(targetDurationController.text) ?? project.durationMonths,
                  minDurationMonths: int.tryParse(minDurationController.text),
                  maxDurationMonths: int.tryParse(maxDurationController.text),
                  repaymentType: selectedRepayment,
                  city: cityController.text,
                  country: project.country,
                  riskRating: project.riskRating,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
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

    setState(() => _isLoading = true);
    final provider = context.read<PortfolioProvider>();

    int importedCount = 0;
    int skippedCount = 0;

    try {
      // Refresh account to get latest transactions
      final account = provider.portfolios
          .expand((p) => p.institutions)
          .expand((i) => i.accounts)
          .firstWhere((a) => a.id == _selectedAccount!.id, orElse: () => _selectedAccount!);

      for (final project in _extractedProjects) {
        // Check for duplicates (Same Name + Same Amount + Same Date)
        final isDuplicate = account.transactions.any((t) =>
            t.assetName == project.projectName &&
            (t.amount - project.investedAmount).abs() < 0.01 &&
            (project.investmentDate == null || isSameDay(t.date, project.investmentDate!)));

        if (isDuplicate) {
          skippedCount++;
          continue;
        }

        // 1. Create Transaction
        final transaction = Transaction(
          id: _uuid.v4(),
          accountId: _selectedAccount!.id,
          type: TransactionType.Buy,
          date: project.investmentDate ?? DateTime.now(),
          assetTicker: project.projectName,
          assetName: project.projectName,
          quantity: 1.0, // Crowdfunding is usually 1 unit of X amount, or X units of 1€. 
                         // Assuming amount is total invested, let's say quantity 1, price = amount.
          price: project.investedAmount,
          amount: project.investedAmount,
          fees: 0.0,
          notes: "Import La Première Brique",
          assetType: AssetType.RealEstateCrowdfunding,
          priceCurrency: 'EUR',
        );

        await provider.addTransaction(transaction);

        // 2. Update Metadata
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

        await provider.updateAssetMetadata(metadata);
        importedCount++;
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<PortfolioProvider>()
        .portfolios
        .expand((p) => p.institutions)
        .expand((i) => i.accounts)
        .toList();

    final selectedAccountReal = _selectedAccount == null 
        ? null 
        : accounts.firstWhere((a) => a.id == _selectedAccount!.id, orElse: () => _selectedAccount!);

    return AppScreen(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: AppDimens.paddingS),
                Text("Import La Première Brique", style: AppTypography.h2),
              ],
            ),
          ),

          // Header / File Picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
            child: AppCard(
              child: Column(
                children: [
                  if (_fileName == null)
                    Center(
                      child: AppButton(
                        label: "Sélectionner le fichier Excel",
                        icon: Icons.upload_file,
                        onPressed: _pickFile,
                      ),
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.insert_drive_file, color: AppColors.primary),
                      title: Text(_fileName!, style: AppTypography.bodyBold),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _fileName = null;
                          _extractedProjects = [];
                        }),
                      ),
                    ),
                  
                  const SizedBox(height: AppDimens.paddingM),
                  
                  DropdownButtonFormField<Account>(
                    decoration: const InputDecoration(
                      labelText: "Compte de destination",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedAccount,
                    items: accounts.map((acc) => DropdownMenuItem(
                      value: acc,
                      child: Text(acc.name),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedAccount = val),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimens.paddingM),

          // List of Projects
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _extractedProjects.isEmpty
                    ? Center(child: Text("Aucun projet à importer", style: AppTypography.body))
                    : ListView.builder(
                        itemCount: _extractedProjects.length,
                        itemBuilder: (context, index) {
                          final project = _extractedProjects[index];
                          final isDuplicate = selectedAccountReal != null && selectedAccountReal.transactions.any((t) =>
                              t.assetName == project.projectName &&
                              (t.amount - project.investedAmount).abs() < 0.01 &&
                              (project.investmentDate == null || isSameDay(t.date, project.investmentDate!)));

                          return FadeInSlide(
                            duration: .1 + (index * .05),
                            child: Dismissible(
                              key: ValueKey(project.projectName),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _removeProject(index),
                              background: Container(
                                color: AppColors.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS / 2),
                                child: AppCard(
                                  backgroundColor: isDuplicate ? AppColors.warning.withOpacity(0.1) : null,
                                  onTap: () => _editProject(index),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(project.projectName, style: AppTypography.bodyBold)),
                                        if (isDuplicate)
                                          const Tooltip(
                                            message: "Ce projet existe déjà et sera ignoré",
                                            child: Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      "${project.investedAmount} € • ${project.yieldPercent}% • ${project.durationMonths} mois",
                                      style: AppTypography.caption,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          project.repaymentType.displayName,
                                          style: AppTypography.caption.copyWith(color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Footer Actions
          if (_extractedProjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: AppButton(
                label: "Importer ${_extractedProjects.length} projets",
                onPressed: _isLoading ? null : _importProjects,
                isFullWidth: true,
              ),
            ),
        ],
      ),
    );
  }
}
