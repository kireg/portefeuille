// lib/features/06_settings/ui/widgets/backup_card.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';

class BackupCard extends StatefulWidget {
  const BackupCard({super.key});

  @override
  State<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<BackupCard> {
  bool _isExporting = false;
  bool _isImporting = false;

  // --- Logique d'Export ---
  Future<void> _handleExport(BuildContext context) async {
    if (!context.mounted) return;
    setState(() => _isExporting = true);
    final provider = context.read<PortfolioProvider>();

    try {
      final jsonString = await provider.getExportJson();

      // Créer un nom de fichier unique
      final timestamp = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '-');
      final fileName = 'portefeuille_backup_$timestamp.json';

      // Sauvegarder le fichier temporairement
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      // Partager le fichier
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Sauvegarde Portefeuille ($timestamp)',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exportation prête pour le partage.'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'exportation: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  // --- Logique d'Import ---
  Future<void> _handleImport(BuildContext context) async {
    // 1. Avertir l'utilisateur
    final bool? confirmed = await _showImportWarning(context);
    if (confirmed != true) return;

    // 2. Choisir le fichier
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Importation annulée.')),
        );
      return;
    }

    if (!context.mounted) return;
    setState(() => _isImporting = true);
    final provider = context.read<PortfolioProvider>();

    try {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // 3. Lancer l'import
      await provider.importDataFromJson(jsonString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Importation réussie ! Les données sont rechargées.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur d\'importation: Fichier invalide ou corrompu.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
    } finally {
      if (context.mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  // --- Dialogue d'avertissement ---
  Future<bool?> _showImportWarning(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 48),
        title: const Text('Importer une sauvegarde ?'),
        content: const Text(
            'ATTENTION : L\'importation d\'une sauvegarde écrasera et remplacera TOUTES les données actuelles (portefeuilles, transactions, paramètres, etc.).\n\nCette action est irréversible.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Écraser et Importer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppTheme.buildStyledCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.buildSectionHeader(
            context: context,
            icon: Icons.save_alt_outlined,
            title: 'Sauvegarde & Restauration',
          ),
          const SizedBox(height: 8),
          Text(
            'Exportez vos données (portefeuilles, transactions, paramètres) dans un fichier JSON. Conservez-le précieusement.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Bouton Exporter
              Expanded(
                child: OutlinedButton.icon(
                  icon: _isExporting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('Exporter'),
                  onPressed: _isExporting || _isImporting ? null : () => _handleExport(context),
                ),
              ),
              const SizedBox(width: 12),
              // Bouton Importer
              Expanded(
                child: FilledButton.icon(
                  icon: _isImporting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_for_offline_outlined, size: 18),
                  label: const Text('Importer'),
                  onPressed: _isExporting || _isImporting ? null : () => _handleImport(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

