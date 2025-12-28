import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/09_imports/services/source_detector.dart';

class WizardStepFile extends StatelessWidget {
  final PlatformFile? selectedFile;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;
  final SourceDetectionResult? detectionResult;
  final bool isDetecting;

  const WizardStepFile({
    super.key,
    required this.selectedFile,
    required this.onPickFile,
    required this.onClearFile,
    this.detectionResult,
    this.isDetecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sélectionnez votre fichier',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Formats supportés : PDF, CSV, Excel (XLSX)',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        if (selectedFile == null)
          Expanded(child: Center(child: _buildUploadArea()))
        else ...[
          _buildFileCard(),
          const SizedBox(height: 16),
          if (isDetecting)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Analyse du fichier...'),
                ],
              ),
            )
          else if (detectionResult != null)
            Expanded(child: _buildPreviewCard()),
        ],
      ],
    );
  }

  Widget _buildPreviewCard() {
    final result = detectionResult!;
    
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isDetected ? Icons.check_circle : Icons.info_outline,
                color: result.isDetected ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message ?? 'Fichier analysé',
                  style: AppTypography.bodyBold.copyWith(
                    color: result.isDetected ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Aperçu du contenu :', style: AppTypography.caption),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  result.preview.isNotEmpty 
                      ? result.preview 
                      : 'Aperçu non disponible',
                  style: AppTypography.caption.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return InkWell(
      onTap: onPickFile,
      borderRadius: BorderRadius.circular(AppDimens.radiusL),
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid, // TODO: Dotted border would be nicer
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cliquez pour parcourir',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 8),
            Text(
              'ou glissez votre fichier ici',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard() {
    final file = selectedFile!;
    final extension = file.extension?.toLowerCase() ?? '';
    
    IconData icon;
    Color color;
    
    switch (extension) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.redAccent;
        break;
      case 'csv':
        icon = Icons.grid_on;
        color = Colors.greenAccent;
        break;
      case 'xlsx':
      case 'xls':
        icon = Icons.table_view;
        color = Colors.green;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = AppColors.textSecondary;
    }

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            file.name,
            style: AppTypography.h3,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _formatFileSize(file.size),
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Changer de fichier',
            type: AppButtonType.secondary,
            onPressed: onPickFile,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
