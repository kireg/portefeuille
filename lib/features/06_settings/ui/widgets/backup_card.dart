// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert'; // Pour utf8
// Pour Uint8List
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/utils/downloader/downloader.dart';
import 'package:portefeuille/core/utils/io_helper.dart';

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
        await getFileDownloader().downloadFile(
          'backup_portefeuille_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json',
          Uint8List.fromList(bytes),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sauvegarde téléchargée')),
          );
        }
      } else if (getIOHelper().isDesktop) {
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
          await getIOHelper().writeFileAsString(outputFile, jsonString);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sauvegarde enregistrée : $outputFile')),
            );
          }
        }
      } else {
        // Mobile: Share
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/backup.json';
        await getIOHelper().writeFileAsString(path, jsonString);
        await Share.shareXFiles([XFile(path)], subject: 'Sauvegarde Portefeuille');
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
        final path = result.files.single.path!;
        jsonString = await getIOHelper().readFileAsString(path);
      }

      if (!mounted) return;
      await context.read<PortfolioProvider>().importDataFromJson(jsonString);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import réussi')));
    } catch (e, stackTrace) {
      debugPrint('Erreur import: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur import: ${e.toString().replaceAll('Exception:', '')}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Détails',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Erreur détaillée'),
                    content: SingleChildScrollView(child: Text('$e\n$stackTrace')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
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