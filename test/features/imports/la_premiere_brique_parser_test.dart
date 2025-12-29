import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/features/09_imports/services/excel/la_premiere_brique_parser.dart';

void main() {
  test('parse LPB Excel with numeric dates populates durations', () async {
    final excel = Excel.createExcel();

    // Sheet "Mes prêts"
    final sheet = excel['Mes prêts'];
    sheet
      ..appendRow([
        TextCellValue('Nom du projet'),
        TextCellValue('Date de signature (JJ/MM/AAAA)'),
        TextCellValue('Date de remboursement minimale (JJ/MM/AAAA)'),
        TextCellValue('Date de remboursement maximale (JJ/MM/AAAA)'),
        TextCellValue('Montant investi (€)'),
        TextCellValue('Taux annuel total (%)'),
      ])
      ..appendRow([
        TextCellValue('Projet Test'),
        // Excel numeric dates (days since 1899-12-30)
        IntCellValue(45500), // 2024-07-13 approx
        IntCellValue(45500 + 180), // min +6 mois approx
        IntCellValue(45500 + 330), // max ~11 mois
        IntCellValue(1000),
        IntCellValue(10),
      ]);

    // Sheet "Échéances" (optional)
    final schedule = excel['Échéances'];
    schedule
      ..appendRow([TextCellValue('Projet'), TextCellValue('Part des intérêts'), TextCellValue('Part du capital')])
      ..appendRow([TextCellValue('Projet Test'), IntCellValue(5), IntCellValue(0)])
      ..appendRow([TextCellValue('Projet Test'), IntCellValue(5), IntCellValue(1000)]);

    final bytes = excel.encode()!;
    final tempDir = await Directory.systemTemp.createTemp('lpb_test_');
    final filePath = '${tempDir.path}/lpb.xlsx';
    await File(filePath).writeAsBytes(bytes, flush: true);

    final platformFile = PlatformFile(
      name: 'lpb.xlsx',
      path: filePath,
      bytes: null,
      size: bytes.length,
    );

    final parser = LaPremiereBriqueParser();
    final projects = await parser.parse(platformFile);

    expect(projects, hasLength(1));
    final p = projects.first;
    expect(p.projectName, 'Projet Test');
    expect(p.minDurationMonths, isNotNull);
    expect(p.maxDurationMonths, isNotNull);
    expect(p.durationMonths, greaterThan(0));
  });
}
