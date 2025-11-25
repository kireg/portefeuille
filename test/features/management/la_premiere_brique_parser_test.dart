import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/features/09_imports/services/excel/la_premiere_brique_parser.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('excel_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('LaPremiereBriqueParser calculates duration correctly', () async {
    // 1. Create Excel file
    var excel = Excel.createExcel();
    // Rename default sheet or use it
    String defaultSheet = excel.getDefaultSheet()!;
    excel.rename(defaultSheet, 'Mes prêts');
    Sheet sheet = excel['Mes prêts'];
    
    // Headers
    List<String> headers = [
      'Nom du projet',
      'Date de signature (JJ/MM/AAAA)',
      'Date de remboursement minimale (JJ/MM/AAAA)',
      'Date de remboursement maximale (JJ/MM/AAAA)',
      'Montant investi (€)',
      'Taux annuel total (%)'
    ];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    // Data Row 1: Min + 6 < Max
    // Sign: 01/01/2023
    // Min: 01/01/2024 (12 months)
    // Max: 01/01/2025 (24 months)
    // Target: 12 + 6 = 18 months
    sheet.appendRow([
      TextCellValue('Projet A'),
      TextCellValue('01/01/2023'),
      TextCellValue('01/01/2024'),
      TextCellValue('01/01/2025'),
      DoubleCellValue(1000.0),
      DoubleCellValue(10.0),
    ]);

    // Data Row 2: Min + 6 > Max
    // Sign: 01/01/2023
    // Min: 01/10/2023 (9 months)
    // Max: 01/01/2024 (12 months)
    // Target: 9 + 6 = 15 > 12 => 12 months
    sheet.appendRow([
      TextCellValue('Projet B'),
      TextCellValue('01/01/2023'),
      TextCellValue('01/10/2023'),
      TextCellValue('01/01/2024'),
      DoubleCellValue(1000.0),
      DoubleCellValue(10.0),
    ]);

    // Save file
    String filePath = '${tempDir.path}/test.xlsx';
    File file = File(filePath);
    List<int>? fileBytes = excel.encode();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }

    // 2. Run Parser
    final parser = LaPremiereBriqueParser();
    final platformFile = PlatformFile(
      name: 'test.xlsx',
      size: file.lengthSync(),
      path: file.path,
      bytes: file.readAsBytesSync(),
    );
    final projects = await parser.parse(platformFile);

    // 3. Assertions
    expect(projects.length, 2);
    
    // Projet A
    expect(projects[0].projectName, 'Projet A');
    expect(projects[0].durationMonths, 18);
    expect(projects[0].minDurationMonths, 12);
    expect(projects[0].maxDurationMonths, 24);

    // Projet B
    expect(projects[1].projectName, 'Projet B');
    expect(projects[1].durationMonths, 12);
    expect(projects[1].minDurationMonths, 9);
    expect(projects[1].maxDurationMonths, 12);
  });
}
