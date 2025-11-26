import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfAnonymizerService {
  Future<String> extractAndSaveToTxt(PlatformFile file) async {
    // 1. Load PDF
    final PdfDocument document = PdfDocument(inputBytes: file.bytes != null ? file.bytes! : File(file.path!).readAsBytesSync());

    // 2. Extract Text
    String text = PdfTextExtractor(document).extractText();
    
    // Dispose document
    document.dispose();

    // 3. Prepare Output File
    final String fileName = file.name.replaceAll('.pdf', '.txt');
    
    // Try to get Desktop path (Windows specific hack or fallback to Downloads)
    String? outputDir;
    
    if (Platform.isWindows) {
      // Try to find Desktop from user profile
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final desktop = Directory('$userProfile\\Desktop');
        if (await desktop.exists()) {
          outputDir = desktop.path;
        }
      }
    }

    // Fallback to Downloads
    if (outputDir == null) {
      final downloads = await getDownloadsDirectory();
      outputDir = downloads?.path;
    }

    // Fallback to Documents
    if (outputDir == null) {
      final docs = await getApplicationDocumentsDirectory();
      outputDir = docs.path;
    }

    final String outputPath = '$outputDir${Platform.pathSeparator}EXTRACTED_$fileName';
    final File outputFile = File(outputPath);

    // 4. Save
    await outputFile.writeAsString(text);

    return outputPath;
  }
}
