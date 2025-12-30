#!/usr/bin/env dart
/// Script pour valider la conformité du Design Center
/// Usage: dart scripts/lint_design_center.dart
/// Scanne tous les fichiers Dart et identifie les violations Design Center

import 'dart:io';
import 'dart:async';

void main(List<String> args) {
  final linter = DesignCenterLinter();
  linter.lint();
}

class DesignCenterLinter {
  static const String libPath = 'lib';
  static const String featurePath = 'lib/features';
  
  /// Règles de violation et leurs corrections
  static const Map<String, String> colorViolations = {
    'Colors.red': 'AppColors.error',
    'Colors.green': 'AppColors.success',
    'Colors.blue': 'AppColors.primary',
    'Colors.white': 'AppColors.white',
    'Colors.black': 'AppColors.textPrimary',
    'Colors.grey': 'AppColors.textSecondary',
    'Colors.redAccent': 'AppColors.error',
    'Colors.greenAccent': 'AppColors.success',
    'Colors.blueAccent': 'AppColors.primary',
  };

  static const List<String> typographyViolations = [
    'fontSize: 10',
    'fontSize: 11',
    'fontSize: 12',
    'fontSize: 14',
    'fontSize: 16',
    'fontSize: 18',
    'fontSize: 20',
    'fontSize: 24',
    'fontSize: 32',
  ];

  static const List<String> dimenViolations = [
    'EdgeInsets.all(4)',
    'EdgeInsets.all(8)',
    'EdgeInsets.all(12)',
    'EdgeInsets.all(16)',
    'EdgeInsets.all(20)',
    'EdgeInsets.all(24)',
    'EdgeInsets.all(32)',
    'BorderRadius.circular(4)',
    'BorderRadius.circular(8)',
    'BorderRadius.circular(12)',
    'BorderRadius.circular(16)',
  ];

  Future<void> lint() async {
    print('🔍 Scan Design Center Compliance...\n');
    
    final dir = Directory(featurePath);
    final files = dir.listSync(recursive: true)
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.freezed.dart') && !f.path.endsWith('.g.dart'))
        .toList();

    int totalViolations = 0;
    final violationsByType = <String, int>{
      'Colors': 0,
      'Typography': 0,
      'Dimensions': 0,
      'Theme': 0,
    };

    final violationsByFile = <String, List<String>>{};

    for (final file in files) {
      if (file is File) {
        final violations = _scanFile(file);
        if (violations.isNotEmpty) {
          violationsByFile[file.path] = violations;
          totalViolations += violations.length;
          
          // Catégoriser les violations
          for (final v in violations) {
            if (v.contains('Colors.')) violationsByType['Colors'] = violationsByType['Colors']! + 1;
            else if (v.contains('fontSize')) violationsByType['Typography'] = violationsByType['Typography']! + 1;
            else if (v.contains('EdgeInsets') || v.contains('BorderRadius')) violationsByType['Dimensions'] = violationsByType['Dimensions']! + 1;
            else if (v.contains('Theme.of')) violationsByType['Theme'] = violationsByType['Theme']! + 1;
          }
        }
      }
    }

    // Afficher les résultats
    _printResults(violationsByFile, violationsByType, totalViolations);
    
    exit(totalViolations > 0 ? 1 : 0);
  }

  List<String> _scanFile(File file) {
    final violations = <String>[];
    final lines = file.readAsLinesSync();
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;
      
      // Check color violations
      for (final color in colorViolations.keys) {
        if (line.contains(color) && !line.contains('AppColors')) {
          violations.add('❌ Line $lineNum: Colors hardcodés: "$color" → "${colorViolations[color]}"');
        }
      }
      
      // Check typography violations
      for (final fontSize in typographyViolations) {
        if (line.contains(fontSize) && !line.contains('AppTypography')) {
          violations.add('❌ Line $lineNum: fontSize hardcodé: "$fontSize" → AppTypography.*');
        }
      }
      
      // Check dimension violations
      for (final dimen in dimenViolations) {
        if (line.contains(dimen) && !line.contains('AppDimens')) {
          violations.add('❌ Line $lineNum: Dimension hardcodée: "$dimen" → AppDimens.*');
        }
      }
      
      // Check Theme.of usage
      if (line.contains('Theme.of') && line.contains('textTheme')) {
        violations.add('❌ Line $lineNum: Theme.of() direct → AppTypography.*');
      }
    }
    
    return violations;
  }

  void _printResults(Map<String, List<String>> violations, Map<String, int> byType, int total) {
    print('═' * 80);
    print('📊 DESIGN CENTER COMPLIANCE REPORT');
    print('═' * 80);
    
    print('\n📈 Résumé par Catégorie:');
    print('   🎨 Colors:      ${byType['Colors']} violations');
    print('   📝 Typography:  ${byType['Typography']} violations');
    print('   📏 Dimensions:  ${byType['Dimensions']} violations');
    print('   🎭 Theme:       ${byType['Theme']} violations');
    print('   ─────────────────────');
    print('   📊 TOTAL:       $total violations');
    
    if (total == 0) {
      print('\n✅ Excellent! Aucune violation détectée.');
      return;
    }

    print('\n📋 Violations par Fichier:');
    violations.forEach((file, violList) {
      print('\n   📄 ${file.replaceAll('lib/features/', '')}');
      for (final v in violList) {
        print('      $v');
      }
    });
    
    print('\n' + '═' * 80);
    print('🚀 Prochaines Étapes:');
    print('   1. Corriger les violations identifiées');
    print('   2. Importer: AppColors, AppTypography, AppDimens');
    print('   3. Relancer: dart scripts/lint_design_center.dart');
    print('═' * 80 + '\n');
  }
}
