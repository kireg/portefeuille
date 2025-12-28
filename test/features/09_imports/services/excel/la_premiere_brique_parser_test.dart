import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/repayment_type.dart';
import 'package:portefeuille/features/09_imports/services/excel/la_premiere_brique_parser.dart';

void main() {
  late LaPremiereBriqueParser parser;
  late Directory tempDir;

  setUp(() async {
    parser = LaPremiereBriqueParser();
    tempDir = await Directory.systemTemp.createTemp('lpb_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<PlatformFile> createExcelFile(Excel excel, String filename) async {
    final bytes = excel.encode()!;
    final filePath = '${tempDir.path}/$filename';
    await File(filePath).writeAsBytes(bytes, flush: true);
    return PlatformFile(
      name: filename,
      path: filePath,
      bytes: null,
      size: bytes.length,
    );
  }

  group('LaPremiereBriqueParser - Parsing de base', () {
    test('parse un projet simple avec dates textuelles', () async {
      final excel = Excel.createExcel();
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
          TextCellValue('Projet Alpha'),
          TextCellValue('15/06/2024'),
          TextCellValue('15/12/2024'),
          TextCellValue('15/06/2025'),
          IntCellValue(5000),
          DoubleCellValue(10.5),
        ]);

      final file = await createExcelFile(excel, 'lpb_simple.xlsx');
      final projects = await parser.parse(file);

      expect(projects, hasLength(1));
      final p = projects.first;
      expect(p.projectName, 'Projet Alpha');
      expect(p.investedAmount, 5000.0);
      expect(p.yieldPercent, 10.5);
      expect(p.platform, 'La Première Brique');
      expect(p.country, 'France');
    });

    test('parse avec dates numériques Excel', () async {
      final excel = Excel.createExcel();
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
          TextCellValue('Projet Beta'),
          IntCellValue(45500), // ~2024-07-13
          IntCellValue(45680), // +180 jours
          IntCellValue(45830), // +330 jours
          IntCellValue(2500),
          IntCellValue(9),
        ]);

      final file = await createExcelFile(excel, 'lpb_numeric_dates.xlsx');
      final projects = await parser.parse(file);

      expect(projects, hasLength(1));
      final p = projects.first;
      expect(p.projectName, 'Projet Beta');
      expect(p.investmentDate, isNotNull);
      expect(p.minDurationMonths, isNotNull);
      expect(p.maxDurationMonths, isNotNull);
      expect(p.durationMonths, greaterThan(0));
    });
  });

  group('LaPremiereBriqueParser - Calcul des durées', () {
    test('calcule durée = min + 6 mois, plafonné par max', () async {
      final excel = Excel.createExcel();
      final sheet = excel['Mes prêts'];
      // Signature: 01/01/2024, Min: 01/07/2024 (6 mois), Max: 01/01/2025 (12 mois)
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
          TextCellValue('Projet Durée'),
          TextCellValue('01/01/2024'),
          TextCellValue('01/07/2024'), // 6 mois
          TextCellValue('01/01/2025'), // 12 mois
          IntCellValue(1000),
          IntCellValue(10),
        ]);

      final file = await createExcelFile(excel, 'lpb_duration.xlsx');
      final projects = await parser.parse(file);

      final p = projects.first;
      expect(p.minDurationMonths, closeTo(6, 1));
      expect(p.maxDurationMonths, closeTo(12, 1));
      // durationMonths = min + 6 = 12, capped at max = 12
      expect(p.durationMonths, closeTo(12, 1));
    });

    test('utilise maxDuration si minDuration est null', () async {
      final excel = Excel.createExcel();
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
          TextCellValue('Projet Sans Min'),
          TextCellValue('01/01/2024'),
          TextCellValue(''), // Pas de date min
          TextCellValue('01/01/2025'), // 12 mois
          IntCellValue(1000),
          IntCellValue(10),
        ]);

      final file = await createExcelFile(excel, 'lpb_no_min.xlsx');
      final projects = await parser.parse(file);

      final p = projects.first;
      expect(p.minDurationMonths, isNull);
      expect(p.durationMonths, closeTo(12, 1));
    });
  });

  group('LaPremiereBriqueParser - Types de remboursement', () {
    test('détecte remboursement In Fine', () async {
      final excel = Excel.createExcel();
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
          TextCellValue('Projet InFine'),
          TextCellValue('01/01/2024'),
          TextCellValue('01/07/2024'),
          TextCellValue('01/01/2025'),
          IntCellValue(1000),
          IntCellValue(10),
        ]);

      // Feuille Échéances avec un seul paiement (capital + intérêts à la fin)
      final schedule = excel['Échéances'];
      schedule
        ..appendRow([
          TextCellValue('Projet'),
          TextCellValue('Part des intérêts'),
          TextCellValue('Part du capital'),
        ])
        ..appendRow([
          TextCellValue('Projet InFine'),
          IntCellValue(100), // Intérêts
          IntCellValue(1000), // Capital
        ]);

      final file = await createExcelFile(excel, 'lpb_infine.xlsx');
      final projects = await parser.parse(file);

      expect(projects.first.repaymentType, RepaymentType.InFine);
    });

    test('détecte remboursement MonthlyInterest', () async {
      final excel = Excel.createExcel();
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
          TextCellValue('Projet Monthly'),
          TextCellValue('01/01/2024'),
          TextCellValue('01/07/2024'),
          TextCellValue('01/01/2025'),
          IntCellValue(1000),
          IntCellValue(10),
        ]);

      // Intérêts mensuels, capital à la fin
      final schedule = excel['Échéances'];
      schedule
        ..appendRow([
          TextCellValue('Projet'),
          TextCellValue('Part des intérêts'),
          TextCellValue('Part du capital'),
        ])
        ..appendRow([TextCellValue('Projet Monthly'), IntCellValue(10), IntCellValue(0)])
        ..appendRow([TextCellValue('Projet Monthly'), IntCellValue(10), IntCellValue(0)])
        ..appendRow([TextCellValue('Projet Monthly'), IntCellValue(10), IntCellValue(1000)]);

      final file = await createExcelFile(excel, 'lpb_monthly.xlsx');
      final projects = await parser.parse(file);

      expect(projects.first.repaymentType, RepaymentType.MonthlyInterest);
    });

    test('détecte remboursement Amortizing', () async {
      final excel = Excel.createExcel();
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
          TextCellValue('Projet Amortizing'),
          TextCellValue('01/01/2024'),
          TextCellValue('01/07/2024'),
          TextCellValue('01/01/2025'),
          IntCellValue(1200),
          IntCellValue(10),
        ]);

      // Remboursement mensuel capital + intérêts
      final schedule = excel['Échéances'];
      schedule
        ..appendRow([
          TextCellValue('Projet'),
          TextCellValue('Part des intérêts'),
          TextCellValue('Part du capital'),
        ])
        ..appendRow([TextCellValue('Projet Amortizing'), IntCellValue(10), IntCellValue(400)])
        ..appendRow([TextCellValue('Projet Amortizing'), IntCellValue(8), IntCellValue(400)])
        ..appendRow([TextCellValue('Projet Amortizing'), IntCellValue(5), IntCellValue(400)]);

      final file = await createExcelFile(excel, 'lpb_amortizing.xlsx');
      final projects = await parser.parse(file);

      expect(projects.first.repaymentType, RepaymentType.Amortizing);
    });

    test('défaut à InFine si pas de feuille Échéances', () async {
      final excel = Excel.createExcel();
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
          TextCellValue('Projet Default'),
          TextCellValue('01/01/2024'),
          TextCellValue('01/07/2024'),
          TextCellValue('01/01/2025'),
          IntCellValue(1000),
          IntCellValue(10),
        ]);

      final file = await createExcelFile(excel, 'lpb_no_schedule.xlsx');
      final projects = await parser.parse(file);

      expect(projects.first.repaymentType, RepaymentType.InFine);
    });
  });

  group('LaPremiereBriqueParser - Projets multiples', () {
    test('parse plusieurs projets', () async {
      final excel = Excel.createExcel();
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
          TextCellValue('Projet A'),
          TextCellValue('01/01/2024'),
          TextCellValue('01/07/2024'),
          TextCellValue('01/01/2025'),
          IntCellValue(1000),
          IntCellValue(10),
        ])
        ..appendRow([
          TextCellValue('Projet B'),
          TextCellValue('15/03/2024'),
          TextCellValue('15/09/2024'),
          TextCellValue('15/03/2025'),
          IntCellValue(2000),
          DoubleCellValue(8.5),
        ])
        ..appendRow([
          TextCellValue('Projet C'),
          TextCellValue('01/06/2024'),
          TextCellValue('01/12/2024'),
          TextCellValue('01/06/2025'),
          IntCellValue(500),
          IntCellValue(12),
        ]);

      final file = await createExcelFile(excel, 'lpb_multi.xlsx');
      final projects = await parser.parse(file);

      expect(projects, hasLength(3));
      expect(projects.map((p) => p.projectName), containsAll(['Projet A', 'Projet B', 'Projet C']));
    });

    test('ignore les lignes vides', () async {
      final excel = Excel.createExcel();
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
          TextCellValue('Projet Valide'),
          TextCellValue('01/01/2024'),
          TextCellValue('01/07/2024'),
          TextCellValue('01/01/2025'),
          IntCellValue(1000),
          IntCellValue(10),
        ])
        ..appendRow([]) // Ligne vide
        ..appendRow([TextCellValue(''), TextCellValue(''), TextCellValue('')]) // Ligne avec cellules vides
        ..appendRow([
          TextCellValue('Autre Projet'),
          TextCellValue('01/02/2024'),
          TextCellValue('01/08/2024'),
          TextCellValue('01/02/2025'),
          IntCellValue(500),
          IntCellValue(9),
        ]);

      final file = await createExcelFile(excel, 'lpb_with_blanks.xlsx');
      final projects = await parser.parse(file);

      expect(projects, hasLength(2));
    });
  });

  group('LaPremiereBriqueParser - Gestion des erreurs', () {
    test('lance une exception si feuille Mes prêts absente', () async {
      final excel = Excel.createExcel();
      excel['Autre Feuille'].appendRow([TextCellValue('Données')]);

      final file = await createExcelFile(excel, 'lpb_no_loans.xlsx');

      expect(
        () => parser.parse(file),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains("Feuille 'Mes prêts' introuvable"),
        )),
      );
    });

    test('gère les montants avec symbole € dans le texte', () async {
      final excel = Excel.createExcel();
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
          TextCellValue('Projet Euro'),
          TextCellValue('01/01/2024'),
          TextCellValue('01/07/2024'),
          TextCellValue('01/01/2025'),
          TextCellValue('1 500,00 €'), // Montant texte formaté
          TextCellValue('10,5%'),
        ]);

      final file = await createExcelFile(excel, 'lpb_formatted.xlsx');
      final projects = await parser.parse(file);

      expect(projects, hasLength(1));
      expect(projects.first.investedAmount, closeTo(1500.0, 0.01));
      expect(projects.first.yieldPercent, closeTo(10.5, 0.1));
    });
  });

  group('LaPremiereBriqueParser - Noms de feuilles alternatifs', () {
    test('trouve la feuille avec accent ou sans', () async {
      final excel = Excel.createExcel();
      // Nom alternatif sans accent
      final sheet = excel['Mes prets'];
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
          TextCellValue('Projet Accent'),
          TextCellValue('01/01/2024'),
          TextCellValue('01/07/2024'),
          TextCellValue('01/01/2025'),
          IntCellValue(1000),
          IntCellValue(10),
        ]);

      final file = await createExcelFile(excel, 'lpb_no_accent.xlsx');
      final projects = await parser.parse(file);

      expect(projects, hasLength(1));
    });
  });
}
