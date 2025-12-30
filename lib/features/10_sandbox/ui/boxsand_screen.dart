import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/10_sandbox/services/pdf_anonymizer_service.dart';

class BoxSandScreen extends StatefulWidget {
  const BoxSandScreen({super.key});

  @override
  State<BoxSandScreen> createState() => _BoxSandScreenState();
}

class _BoxSandScreenState extends State<BoxSandScreen> {
  final PdfAnonymizerService _service = PdfAnonymizerService();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  Future<void> _pickAndProcess() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = result.files.single;
        final path = await _service.extractAndSaveToTxt(file);
        
        setState(() {
          _statusMessage = "Succès !\nFichier enregistré sous :\n$path";
          _isError = false;
        });
      } else {
        setState(() {
          _statusMessage = "Aucun fichier sélectionné.";
          _isError = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Erreur : $e";
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BoxSand - Extraction PDF"),
        backgroundColor: AppColors.background,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.build_circle_outlined, size: AppComponentSizes.iconXxLarge, color: AppColors.primary),
              const SizedBox(height: AppDimens.paddingL),
              Text(
                "Outil d'extraction de texte PDF",
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                "Importez un PDF pour extraire tout son contenu texte brut.\nUtile pour le débogage et l'anonymisation.",
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.paddingXL),
              
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _pickAndProcess,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Sélectionner un PDF"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),

              if (_statusMessage != null) ...[
                const SizedBox(height: AppDimens.paddingXL),
                AppCard(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: Column(
                      children: [
                        Icon(
                          _isError ? Icons.error_outline : Icons.check_circle_outline,
                          color: _isError ? AppColors.error : AppColors.success,
                          size: AppComponentSizes.iconLarge,
                        ),
                        AppSpacing.gapS,
                        SelectableText(
                          _statusMessage!,
                          style: AppTypography.body.copyWith(
                            color: _isError ? AppColors.error : AppColors.success,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
