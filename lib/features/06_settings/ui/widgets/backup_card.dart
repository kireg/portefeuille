import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';

class BackupCard extends StatefulWidget {
  const BackupCard({super.key});
  @override
  State<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<BackupCard> {
  bool _isBusy = false;

  Future<void> _handleExport(BuildContext context) async {
    setState(() => _isBusy = true);
    final provider = context.read<PortfolioProvider>();
    try {
      final jsonString = await provider.getExportJson();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/backup.json');
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(file.path)], subject: 'Sauvegarde Portefeuille');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null) return;

    if (!mounted) return;
    setState(() => _isBusy = true);

    try {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      await context.read<PortfolioProvider>().importDataFromJson(jsonString);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import réussi')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur import')));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const AppIcon(icon: Icons.save_alt, color: AppColors.accent),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sauvegarde', style: AppTypography.h3),
                    Text('Export JSON', style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingL),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Exporter',
                  icon: Icons.upload,
                  isLoading: _isBusy,
                  onPressed: () => _handleExport(context),
                ),
              ),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: AppButton(
                  label: 'Importer',
                  icon: Icons.download,
                  type: AppButtonType.secondary,
                  isLoading: _isBusy,
                  onPressed: () => _handleImport(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}