import 'dart:io';
import 'package:excel/excel.dart';
import 'package:portefeuille/core/data/models/repayment_type.dart';
import 'parsed_crowdfunding_project.dart';

class LaPremiereBriqueParser {
  
  Future<List<ParsedCrowdfundingProject>> parse(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    Sheet? loansSheet;
    Sheet? scheduleSheet;
    
    for (var table in excel.tables.keys) {
      final lowerTable = table.toLowerCase();
      if (lowerTable.contains("prêts") || lowerTable.contains("prets")) {
        loansSheet = excel.tables[table];
      } else if (lowerTable.contains("échéances") || lowerTable.contains("echeances")) {
        scheduleSheet = excel.tables[table];
      }
    }
    
    if (loansSheet == null) {
      throw Exception("Feuille 'Mes prêts' introuvable. Assurez-vous d'importer le fichier Excel complet de La Première Brique.");
    }
    
    return _processSheets(loansSheet, scheduleSheet);
  }

  List<ParsedCrowdfundingProject> _processSheets(Sheet loansSheet, Sheet? scheduleSheet) {
    List<ParsedCrowdfundingProject> projects = [];
    
    // --- 1. Parse Loans Sheet ---
    int headerRowIndex = -1;
    Map<String, int> headers = {};
    
    for (int i = 0; i < loansSheet.maxRows; i++) {
      final row = loansSheet.row(i);
      if (row.any((cell) => _getCellValue(cell).toString().contains("Nom du projet"))) {
        headerRowIndex = i;
        for (int j = 0; j < row.length; j++) {
          final val = _getCellValue(row[j])?.toString();
          if (val != null) headers[val] = j;
        }
        break;
      }
    }
    
    if (headerRowIndex == -1) throw Exception("En-têtes non trouvés dans la feuille 'Mes prêts'");
    
    // --- 2. Parse Schedule Sheet (for repayment type) ---
    Map<String, RepaymentType> repaymentTypes = {};
    if (scheduleSheet != null) {
      repaymentTypes = _parseRepaymentTypes(scheduleSheet);
    }

    // --- 3. Iterate Rows ---
    for (int i = headerRowIndex + 1; i < loansSheet.maxRows; i++) {
      final row = loansSheet.row(i);
      if (row.isEmpty) continue;
      
      final nameIdx = headers['Nom du projet'];
      if (nameIdx == null || nameIdx >= row.length) continue;
      
      final projectName = _getCellValue(row[nameIdx])?.toString();
      if (projectName == null || projectName.isEmpty) continue;
      
      // Dates
      final dateSignIdx = headers['Date de signature (JJ/MM/AAAA)'];
      final dateEndIdx = headers['Date de remboursement maximale (JJ/MM/AAAA)'];
      
      DateTime? startDate = (dateSignIdx != null && dateSignIdx < row.length) 
          ? _parseDate(row[dateSignIdx]) 
          : null;
          
      DateTime? endDate = (dateEndIdx != null && dateEndIdx < row.length) 
          ? _parseDate(row[dateEndIdx]) 
          : null;
      
      // Duration
      int durationMonths = 0;
      if (startDate != null && endDate != null) {
        durationMonths = ((endDate.difference(startDate).inDays) / 30.437).round();
      }
      
      // Amount
      final amountIdx = headers['Montant investi (€)'];
      double amount = 0.0;
      if (amountIdx != null && amountIdx < row.length) {
        amount = _parseDouble(row[amountIdx]) ?? 0.0;
      }
      
      // Rate
      final rateIdx = headers['Taux annuel total (%)'];
      double rate = 0.0;
      if (rateIdx != null && rateIdx < row.length) {
        rate = _parseDouble(row[rateIdx]) ?? 0.0;
      }
      
      // Repayment Type
      RepaymentType type = repaymentTypes[projectName] ?? RepaymentType.InFine;
      
      projects.add(ParsedCrowdfundingProject(
        projectName: projectName,
        platform: "La Première Brique",
        investmentDate: startDate,
        investedAmount: amount,
        yieldPercent: rate,
        durationMonths: durationMonths,
        repaymentType: type,
        country: "France",
      ));
    }
    
    return projects;
  }
  
  Map<String, RepaymentType> _parseRepaymentTypes(Sheet sheet) {
    Map<String, RepaymentType> types = {};
    
    int headerRowIndex = -1;
    Map<String, int> headers = {};
    
    for (int i = 0; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.any((cell) => _getCellValue(cell).toString().contains("Projet"))) {
        headerRowIndex = i;
        for (int j = 0; j < row.length; j++) {
          final val = _getCellValue(row[j])?.toString();
          if (val != null) headers[val] = j;
        }
        break;
      }
    }
    
    if (headerRowIndex == -1) return {};
    
    Map<String, List<Map<String, double>>> projectSchedules = {};
    
    final projectIdx = headers['Projet'];
    final interestIdx = headers['Part des intérêts'];
    final capitalIdx = headers['Part du capital'];
    
    if (projectIdx == null || interestIdx == null || capitalIdx == null) return {};

    for (int i = headerRowIndex + 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty) continue;
      
      if (projectIdx >= row.length) continue;
      final projectName = _getCellValue(row[projectIdx])?.toString();
      if (projectName == null) continue;
      
      double interest = 0.0;
      if (interestIdx < row.length) {
        interest = _parseDouble(row[interestIdx]) ?? 0.0;
      }
      
      double capital = 0.0;
      if (capitalIdx < row.length) {
        capital = _parseDouble(row[capitalIdx]) ?? 0.0;
      }
      
      projectSchedules.putIfAbsent(projectName, () => []).add({
        'interest': interest,
        'capital': capital,
      });
    }
    
    projectSchedules.forEach((name, rows) {
      int rowsWithInterest = rows.where((r) => r['interest']! > 0).length;
      int rowsWithCapital = rows.where((r) => r['capital']! > 0).length;
      
      if (rowsWithCapital > 1) {
        types[name] = RepaymentType.Amortizing;
      } else if (rowsWithInterest > 1) {
        types[name] = RepaymentType.MonthlyInterest;
      } else {
        types[name] = RepaymentType.InFine;
      }
    });
    
    return types;
  }

  dynamic _getCellValue(Data? cell) {
    if (cell == null) return null;
    return cell.value;
  }

  DateTime? _parseDate(Data? cell) {
    if (cell == null) return null;
    final val = cell.value;
    
    if (val is DateCellValue) {
      return DateTime(val.year, val.month, val.day);
    }
    if (val is TextCellValue) {
      try {
        final parts = val.value.toString().split('/');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
    }
    return null;
  }

  double? _parseDouble(Data? cell) {
    if (cell == null) return null;
    final val = cell.value;
    
    if (val is DoubleCellValue) return val.value;
    if (val is IntCellValue) return val.value.toDouble();
    if (val is TextCellValue) {
      String clean = val.value.toString().replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
      return double.tryParse(clean);
    }
    return null;
  }
}
