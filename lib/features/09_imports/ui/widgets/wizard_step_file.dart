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
      padding: const EdgeInsets.all(AppDimens.paddingM),
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
              padding: const EdgeInsets.all(AppDimens.paddingS),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: SingleChildScrollView(
                child: Text(
                  result.preview.isNotEmpty 
                      ? result.preview 
                      : 'Aperçu non disponible',
                  style: AppTypography.caption.copyWith(
                    fontFamily: 'monospace',
                    fontSize: AppTypography.small.fontSize,
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
        ),
        foregroundDecoration: ShapeDecoration(
          shape: DashedBorder(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2,
            dashLength: 8,
            gapLength: 4,
            radius: AppDimens.radiusL,
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
        color = AppColors.error;
        break;
      case 'csv':
        icon = Icons.grid_on;
        color = AppColors.success;
        break;
      case 'xlsx':
      case 'xls':
        icon = Icons.table_view;
        color = AppColors.success;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = AppColors.textSecondary;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.paddingL),
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

/// Custom border painter pour créer une bordure en pointillés
class DashedBorder extends ShapeBorder {
  final Color color;
  final double width;
  final double dashLength;
  final double gapLength;
  final double radius;

  const DashedBorder({
    required this.color,
    required this.width,
    required this.dashLength,
    required this.gapLength,
    required this.radius,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        rect.deflate(width),
        Radius.circular(radius),
      ));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        rect,
        Radius.circular(radius),
      ));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(width / 2),
      Radius.circular(radius),
    );

    // Calculer le périmètre approximatif
    final perimeter = 2 * (rrect.width + rrect.height);
    final dashCount = (perimeter / (dashLength + gapLength)).floor();

    // Dessiner les traits en pointillés sur chaque côté
    _drawDashedLine(canvas, paint, rrect.left, rrect.top, rrect.right, rrect.top, dashCount ~/ 4); // Top
    _drawDashedLine(canvas, paint, rrect.right, rrect.top, rrect.right, rrect.bottom, dashCount ~/ 4); // Right
    _drawDashedLine(canvas, paint, rrect.right, rrect.bottom, rrect.left, rrect.bottom, dashCount ~/ 4); // Bottom
    _drawDashedLine(canvas, paint, rrect.left, rrect.bottom, rrect.left, rrect.top, dashCount ~/ 4); // Left
  }

  void _drawDashedLine(Canvas canvas, Paint paint, double x1, double y1, double x2, double y2, int segments) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final lineLength = (dx * dx + dy * dy);
    if (lineLength == 0) return;

    final unitDx = dx / lineLength;
    final unitDy = dy / lineLength;

    double currentX = x1;
    double currentY = y1;
    bool drawing = true;

    for (int i = 0; i < segments * 2; i++) {
      final segmentLength = drawing ? dashLength : gapLength;
      final nextX = currentX + unitDx * segmentLength;
      final nextY = currentY + unitDy * segmentLength;

      if (drawing) {
        canvas.drawLine(Offset(currentX, currentY), Offset(nextX, nextY), paint);
      }

      currentX = nextX;
      currentY = nextY;
      drawing = !drawing;
    }
  }

  @override
  ShapeBorder scale(double t) {
    return DashedBorder(
      color: color,
      width: width * t,
      dashLength: dashLength * t,
      gapLength: gapLength * t,
      radius: radius * t,
    );
  }
}

