import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/csv/parsers/revolut_parser.dart';

void main() {
  final parser = RevolutParser();

  test('parse Revolut CSV trading statement', () async {
    const raw = '''
Date,Ticker,Type,Quantity,Price per share,Total Amount,Currency,FX Rate
2025-01-31T14:53:37.864Z,NVDA,BUY - MARKET,16.13293538,USD 123.97,USD 2000,USD,1.0397
2025-03-14T15:26:11.874829Z,MSFT,DIVIDEND,,,USD 1.41,USD,1.0905
2025-07-02T20:59:22.856710Z,MSFT,DIVIDEND TAX (CORRECTION),,,USD -0.25,USD,1.1826
2025-01-31T15:19:16.970881Z,,CASH TOP-UP,,,EUR 435.44,EUR,1.0000
''';
    final result = await parser.parse(raw);
    expect(result, hasLength(4));

    final buy = result.firstWhere((tx) => tx.type == TransactionType.Buy);
    expect(buy.ticker, 'NVDA');
    expect(buy.amount, closeTo(-2000, 0.001)); // Négatif: sortie d'argent
    expect(buy.price, closeTo(123.97, 0.001));

    final dividend = result.firstWhere((tx) => tx.type == TransactionType.Dividend);
    expect(dividend.amount, closeTo(1.41, 0.001));

    final fees = result.firstWhere((tx) => tx.type == TransactionType.Fees);
    expect(fees.amount, closeTo(0.25, 0.001));

    final deposit = result.firstWhere((tx) => tx.type == TransactionType.Deposit);
    expect(deposit.amount, closeTo(435.44, 0.001));
    expect(deposit.assetType, AssetType.Cash);
  });

  test('parse Revolut XLSX statement sample', () async {
    final sampleFile = File('docs/trading-account-statement_2023-09-04_2025-12-24_fr-fr_b70449.xlsx');
    if (!await sampleFile.exists()) {
      // Skip si le fichier de test n'existe pas (environnement CI ou fichier non fourni)
      markTestSkipped('Fichier de test XLSX non disponible');
      return;
    }
    
    final bytes = await sampleFile.readAsBytes();
    final text = _excelToText(bytes);
    final result = await parser.parse(text);

    expect(result, hasLength(26));
    expect(result.where((tx) => tx.type == TransactionType.Buy), isNotEmpty);
    expect(result.where((tx) => tx.type == TransactionType.Dividend), isNotEmpty);
    expect(result.where((tx) => tx.type == TransactionType.Deposit), isNotEmpty);
  });
}

String _excelToText(List<int> bytes) {
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) return '';

  final buffer = StringBuffer();
  final sheet = excel.tables.values.first;

  for (final row in sheet.rows) {
    final cells = row.map((cell) {
      final value = cell?.value;
      if (value == null) return '';
      if (value is TextCellValue) return value.value.toString();
      if (value is DateCellValue) {
        return DateTime(value.year, value.month, value.day).toIso8601String();
      }
      return value.toString();
    }).toList();

    if (cells.every((value) => value.trim().isEmpty)) continue;
    buffer.writeln(cells.join(','));
  }

  return buffer.toString();
}
