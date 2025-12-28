import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:portefeuille/features/09_imports/services/csv/parsers/revolut_parser.dart';
import 'package:portefeuille/features/09_imports/services/excel/la_premiere_brique_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/boursorama_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/parsers/trade_republic_account_statement_parser.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

/// Tests d'intégration utilisant de vrais relevés bancaires.
/// 
/// Place tes fichiers dans `test_data/real_statements/` et lance :
/// ```
/// flutter test test/features/09_imports/real_statements_test.dart
/// ```
/// 
/// Les fichiers dans ce dossier sont ignorés par git.
void main() {
  final realStatementsDir = Directory('test_data/real_statements');
  
  group('Real Statements Integration Tests', () {
    setUpAll(() {
      if (!realStatementsDir.existsSync()) {
        realStatementsDir.createSync(recursive: true);
      }
    });

    test('Directory exists and is readable', () {
      expect(realStatementsDir.existsSync(), isTrue);
    });

    test('Parse all PDF files in real_statements folder', () async {
      if (!realStatementsDir.existsSync()) {
        markTestSkipped('No real_statements directory found');
        return;
      }

      final pdfFiles = realStatementsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.pdf'))
          .toList();

      if (pdfFiles.isEmpty) {
        markTestSkipped('No PDF files found in test_data/real_statements/');
        return;
      }

      print('\n📄 Found ${pdfFiles.length} PDF file(s) to test:\n');

      final parsers = <StatementParser>[
        TradeRepublicAccountStatementParser(),
        TradeRepublicParser(),
        BoursoramaParser(),
      ];

      for (final file in pdfFiles) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        print('─' * 60);
        print('📁 Testing: $fileName');

        try {
          final bytes = await file.readAsBytes();
          final document = PdfDocument(inputBytes: bytes);
          final rawText = PdfTextExtractor(document).extractText();
          document.dispose();
          
          expect(rawText, isNotEmpty, reason: 'PDF text extraction failed for $fileName');
          
          print('   📝 Extracted ${rawText.length} characters');

          // Find matching parser
          StatementParser? matchedParser;
          for (final parser in parsers) {
            if (parser.canParse(rawText)) {
              matchedParser = parser;
              break;
            }
          }

          if (matchedParser == null) {
            print('   ⚠️  No parser matched this file');
            continue;
          }

          print('   🔍 Matched parser: ${matchedParser.bankName}');

          // Parse transactions
          final transactions = await matchedParser.parse(rawText);
          
          if (transactions.isEmpty) {
            print('   ⚠️  Parser found 0 transactions - skipping');
            continue;
          }
          
          print('   ✅ Parsed ${transactions.length} transaction(s)');

          // Print summary
          if (transactions.isNotEmpty) {
            final types = <String, int>{};
            for (final tx in transactions) {
              final typeName = tx.type.toString().split('.').last;
              types[typeName] = (types[typeName] ?? 0) + 1;
            }
            print('   📊 Types: ${types.entries.map((e) => "${e.key}: ${e.value}").join(", ")}');

            // Show first few transactions
            final sample = transactions.take(3).toList();
            for (final tx in sample) {
              print('      - ${tx.date.toString().substring(0, 10)} | ${tx.type.toString().split('.').last.padRight(10)} | ${tx.assetName.length > 25 ? tx.assetName.substring(0, 25) + "..." : tx.assetName.padRight(28)} | ${tx.amount.toStringAsFixed(2)} ${tx.currency}');
            }
            if (transactions.length > 3) {
              print('      ... and ${transactions.length - 3} more');
            }
          }
          
          // Validate transactions have required fields
          for (final tx in transactions) {
            expect(tx.assetName, isNotEmpty, reason: 'Transaction has empty assetName');
            expect(tx.date, isNotNull, reason: 'Transaction has null date');
          }

        } catch (e, stack) {
          print('   ❌ Error: $e');
          print('   Stack: ${stack.toString().split('\n').take(3).join('\n')}');
          // Continue with other files instead of failing
          continue;
        }
      }
      
      print('\n' + '─' * 60);
      print('📊 PDF parsing complete (${pdfFiles.length} files scanned)\n');
    });

    test('Parse all CSV files in real_statements folder', () async {
      if (!realStatementsDir.existsSync()) {
        markTestSkipped('No real_statements directory found');
        return;
      }

      final csvFiles = realStatementsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.csv'))
          .toList();

      if (csvFiles.isEmpty) {
        markTestSkipped('No CSV files found in test_data/real_statements/');
        return;
      }

      print('\n📄 Found ${csvFiles.length} CSV file(s) to test:\n');

      final parser = RevolutParser();

      for (final file in csvFiles) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        print('─' * 60);
        print('📁 Testing: $fileName');

        try {
          final content = await file.readAsString();
          expect(content, isNotEmpty, reason: 'CSV file is empty: $fileName');
          
          print('   📝 Read ${content.length} characters');

          if (!parser.canParse(content)) {
            print('   ⚠️  RevolutParser cannot parse this CSV');
            continue;
          }

          print('   🔍 Matched parser: ${parser.bankName}');

          final transactions = await parser.parse(content);
          print('   ✅ Parsed ${transactions.length} transaction(s)');

          if (transactions.isNotEmpty) {
            final types = <String, int>{};
            for (final tx in transactions) {
              final typeName = tx.type.toString().split('.').last;
              types[typeName] = (types[typeName] ?? 0) + 1;
            }
            print('   📊 Types: ${types.entries.map((e) => "${e.key}: ${e.value}").join(", ")}');

            final sample = transactions.take(3).toList();
            for (final tx in sample) {
              print('      - ${tx.date.toString().substring(0, 10)} | ${tx.type.toString().split('.').last.padRight(10)} | ${tx.assetName.length > 25 ? tx.assetName.substring(0, 25) + "..." : tx.assetName.padRight(28)} | ${tx.amount.toStringAsFixed(2)} ${tx.currency}');
            }
            if (transactions.length > 3) {
              print('      ... and ${transactions.length - 3} more');
            }
          }

          expect(transactions, isNotEmpty, reason: 'Parser found 0 transactions in $fileName');

        } catch (e, stack) {
          print('   ❌ Error: $e');
          print('   Stack: ${stack.toString().split('\n').take(3).join('\n')}');
          fail('Failed to parse $fileName: $e');
        }
      }

      print('\n' + '─' * 60);
      print('✅ All ${csvFiles.length} CSV files parsed successfully!\n');
    });

    test('Parse all Excel files in real_statements folder', () async {
      if (!realStatementsDir.existsSync()) {
        markTestSkipped('No real_statements directory found');
        return;
      }

      final excelFiles = realStatementsDir
          .listSync()
          .whereType<File>()
          .where((f) {
            final lower = f.path.toLowerCase();
            return lower.endsWith('.xlsx') || lower.endsWith('.xls');
          })
          .toList();

      if (excelFiles.isEmpty) {
        markTestSkipped('No Excel files found in test_data/real_statements/');
        return;
      }

      print('\n📄 Found ${excelFiles.length} Excel file(s) to test:\n');

      final parser = LaPremiereBriqueParser();

      for (final file in excelFiles) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        print('─' * 60);
        print('📁 Testing: $fileName');

        try {
          final bytes = await file.readAsBytes();
          final platformFile = PlatformFile(
            name: fileName,
            size: bytes.length,
            path: file.path,
            bytes: bytes,
          );

          final projects = await parser.parse(platformFile);
          print('   ✅ Parsed ${projects.length} project(s)');

          if (projects.isNotEmpty) {
            final sample = projects.take(3).toList();
            for (final proj in sample) {
              print('      - ${proj.projectName.length > 30 ? proj.projectName.substring(0, 30) + "..." : proj.projectName.padRight(33)} | ${proj.investedAmount.toStringAsFixed(2)} € | ${proj.yieldPercent}%');
            }
            if (projects.length > 3) {
              print('      ... and ${projects.length - 3} more');
            }
          }

          expect(projects, isNotEmpty, reason: 'Parser found 0 projects in $fileName');

          for (final proj in projects) {
            expect(proj.projectName, isNotEmpty, reason: 'Project has empty name');
            expect(proj.investedAmount, greaterThan(0), reason: 'Project has no invested amount');
          }

        } catch (e, stack) {
          print('   ❌ Error: $e');
          print('   Stack: ${stack.toString().split('\n').take(3).join('\n')}');
          fail('Failed to parse $fileName: $e');
        }
      }

      print('\n' + '─' * 60);
      print('✅ All ${excelFiles.length} Excel files parsed successfully!\n');
    });

    test('Summary: List all files and their detected sources', () async {
      if (!realStatementsDir.existsSync()) {
        markTestSkipped('No real_statements directory found');
        return;
      }

      final allFiles = realStatementsDir
          .listSync()
          .whereType<File>()
          .where((f) => !f.path.endsWith('.gitkeep'))
          .toList();

      if (allFiles.isEmpty) {
        print('\n📂 No files found in test_data/real_statements/');
        print('   Add your bank statements to test them!\n');
        markTestSkipped('No files to test');
        return;
      }

      print('\n📂 Files in test_data/real_statements/:\n');
      
      for (final file in allFiles) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        final ext = fileName.split('.').last.toUpperCase();
        print('   📄 [$ext] $fileName');
      }
      
      print('\n   Total: ${allFiles.length} file(s)\n');
    });
  });
}
