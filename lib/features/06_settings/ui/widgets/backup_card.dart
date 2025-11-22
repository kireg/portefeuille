// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // Pour utf8
// Pour Uint8List
import 'package:flutter/foundation.dart'; // Pour kIsWeb
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

      if (kIsWeb) {
        // --- WEB ---
        final bytes = utf8.encode(jsonString);
        await FilePicker.platform.saveFile(
          fileName: 'backup_portefeuille_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json',
          bytes: Uint8List.fromList(bytes),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sauvegarde téléchargée')),
          );
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: Save File Dialog
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Enregistrer la sauvegarde',
          fileName: 'backup_portefeuille_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json',
          allowedExtensions: ['json'],
          type: FileType.custom,
        );

        if (outputFile != null) {
          // Ensure extension
          if (!outputFile.toLowerCase().endsWith('.json')) {
            outputFile = '$outputFile.json';
          }
          final file = File(outputFile);
          await file.writeAsString(jsonString);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sauvegarde enregistrée : $outputFile')),
            );
          }
        }
      } else {
        // Mobile: Share
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/backup.json');
        await file.writeAsString(jsonString);
        await Share.shareXFiles([XFile(file.path)], subject: 'Sauvegarde Portefeuille');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true, // Important pour le Web
    );
    if (result == null) return;

    if (!mounted) return;
    setState(() => _isBusy = true);

    try {
      String jsonString;
      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes == null) throw Exception("Fichier vide ou illisible");
        jsonString = utf8.decode(bytes);
      } else {
        final file = File(result.files.single.path!);
        jsonString = await file.readAsString();
      }

      if (!mounted) return;
      await context.read<PortfolioProvider>().importDataFromJson(jsonString);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import réussi')));
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