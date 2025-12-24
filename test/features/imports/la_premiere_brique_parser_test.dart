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
        'Nom du projet',
        'Date de signature (JJ/MM/AAAA)',
        'Date de remboursement minimale (JJ/MM/AAAA)',
        'Date de remboursement maximale (JJ/MM/AAAA)',
        'Montant investi (€)',
        'Taux annuel total (%)',
      ])
      ..appendRow([
        'Projet Test',
        // Excel numeric dates (days since 1899-12-30)
        45500, // 2024-07-13 approx
        45500 + 180, // min +6 mois approx
        45500 + 330, // max ~11 mois
        1000,
        10,
      ]);

    // Sheet "Échéances" (optional)
    final schedule = excel['Échéances'];
    schedule
      ..appendRow(['Projet', 'Part des intérêts', 'Part du capital'])
      ..appendRow(['Projet Test', 5, 0])
      ..appendRow(['Projet Test', 5, 1000]);

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
