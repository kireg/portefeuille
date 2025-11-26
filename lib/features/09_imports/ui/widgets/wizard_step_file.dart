import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
// import 'package:dotted_border/dotted_border.dart'; // Si disponible, sinon Border.all avec dash pattern manuel ou simple

class WizardStepFile extends StatelessWidget {
  final PlatformFile? selectedFile;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  const WizardStepFile({
    super.key,
    required this.selectedFile,
    required this.onPickFile,
    required this.onClearFile,
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
        const SizedBox(height: 32),
        
        Expanded(
          child: Center(
            child: selectedFile == null
                ? _buildUploadArea()
                : _buildFileCard(),
          ),
        ),
      ],
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
