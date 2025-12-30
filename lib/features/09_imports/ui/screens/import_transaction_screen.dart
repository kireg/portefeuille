// lib/features/07_management/ui/screens/import_transaction_screen.dart

import 'dart:io';
import 'dart:ui' as ui; // Nécessaire pour la manipulation d'image
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/data/services/ai_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

class ImportTransactionScreen extends StatefulWidget {
  const ImportTransactionScreen({super.key});

  @override
  State<ImportTransactionScreen> createState() => _ImportTransactionScreenState();
}

class _ImportTransactionScreenState extends State<ImportTransactionScreen> {
  final _cropController = CropController();
  Uint8List? _imageData;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickFile());
  }

  /// Cette fonction magique prend une image (peut-être transparente)
  /// et la dessine sur un fond BLANC pur.
  Future<Uint8List> _flattenTransparency(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()));

    // 1. On remplit tout en BLANC
    canvas.drawRect(
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Paint()..color = AppColors.white
    );

    // 2. On dessine l'image (PDF) par dessus
    canvas.drawImage(image, Offset.zero, Paint());

    final picture = recorder.endRecording();
    final img = await picture.toImage(image.width, image.height);
    // On exporte en PNG (qui aura maintenant un fond blanc opaque)
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> _pickFile() async {
    setState(() { _isLoading = true; _statusMessage = 'Ouverture du PDF...'; });
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );

      if (result != null) {
        final platformFile = result.files.single;
        final isPdf = platformFile.extension?.toLowerCase() == 'pdf' || 
                      platformFile.name.toLowerCase().endsWith('.pdf');
        
        Uint8List bytes;
        if (kIsWeb) {
           bytes = platformFile.bytes!;
        } else {
           bytes = await File(platformFile.path!).readAsBytes();
        }

        if (isPdf) {
          await _renderPdfPage(bytes);
        } else {
          // Même pour une image JPG/PNG directe, on force le fond blanc par sécurité
          final flatBytes = await _flattenTransparency(bytes);

          setState(() { _imageData = flatBytes; _statusMessage = 'Sélectionnez la zone'; });
        }
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showError("Erreur fichier: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _renderPdfPage(Uint8List pdfBytes) async {
    try {
      // On reste en DPI 300 pour la qualité OCR
      await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
        final pngBytes = await page.toPng();

        // ICI : On applique le fond blanc avant de stocker l'image
        final whiteBgBytes = await _flattenTransparency(pngBytes);

        if (mounted) {
          setState(() { _imageData = whiteBgBytes; _statusMessage = 'Sélectionnez la zone'; });
        }
        break;
      }
    } catch (e) {
      _showError("Impossible de lire le PDF.");
    }
  }

  void _processCrop(Uint8List croppedData) async {
    final settings = context.read<SettingsProvider>();

    // --- DEBUG VISUEL (A garder) ---
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Vérification Image"),
        content: Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.error)),
            child: Image.memory(croppedData)
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Envoyer à l'IA"))],
      ),
    );
    // ---------------------------------------------------------

    if (!settings.hasGeminiApiKey) {
      _showError("Clé API Gemini manquante.");
      return;
    }

    setState(() { _isLoading = true; _statusMessage = 'Analyse des transactions...'; });

    try {
      final aiService = AiService(apiKey: settings.geminiApiKey!);
      final results = await aiService.extractTransactionData(croppedData);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (results.isNotEmpty) {
        Navigator.pop(context, results);
      } else {
        _showError("Aucune transaction trouvée sur cette zone.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Erreur API: $e");
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Intelligent'),
        actions: [
          if (_imageData != null && !_isLoading)
            IconButton(icon: const Icon(Icons.check), onPressed: () => _cropController.crop())
        ],
      ),
      body: _isLoading
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), AppSpacing.gapM, Text(_statusMessage)]))
          : _imageData == null
          ? Center(child: ElevatedButton(onPressed: _pickFile, child: const Text("Sélectionner un fichier")))
          : Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Crop(
          image: _imageData!,
          controller: _cropController,
          onCropped: (image) => _processCrop(image),
          // Le baseColor ne sert que visuellement pour le Crop,
          // mais notre image _imageData a maintenant son propre fond blanc "incrusté".
          baseColor: AppColors.background,
          maskColor: AppColors.blackOverlay60,
          initialSize: 0.7,
          interactive: !_isLoading,
        ),
      ),
    );
  }
}