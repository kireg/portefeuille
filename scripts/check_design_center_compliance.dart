#!/usr/bin/env dart
// Script pour vérifier la conformité 100% Design Center
// Usage: dart run scripts/check_design_center_compliance.dart

import 'dart:io';

void main() async {
  print('🎨 Vérification de la conformité Design Center...\n');

  final violations = <DesignCenterViolation>[];
  final libDir = Directory('lib');

  // Scanner tous les fichiers Dart
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      // Exclure les fichiers générés
      if (file.path.contains('.g.dart') ||
          file.path.contains('.freezed.dart') ||
          file.path.contains('generated')) {
        continue;
      }

      final content = await file.readAsString();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lineNumber = i + 1;

        // Ignorer les commentaires
        if (line.trim().startsWith('//')) continue;

        // Détecter les violations
        violations.addAll(_checkDurationHardcodes(file.path, lineNumber, line));
        violations.addAll(_checkEdgeInsetsHardcodes(file.path, lineNumber, line));
        violations.addAll(_checkSizedBoxHardcodes(file.path, lineNumber, line));
        violations.addAll(_checkBoxShadowHardcodes(file.path, lineNumber, line));
        violations.addAll(_checkOpacityHardcodes(file.path, lineNumber, line));
        violations.addAll(_checkNumericSizeHardcodes(file.path, lineNumber, line));
        violations.addAll(_checkBorderRadiusHardcodes(file.path, lineNumber, line));
      }
    }
  }

  // Afficher les résultats
  if (violations.isEmpty) {
    print('✅ Aucune violation détectée ! Application 100% Design Center compliant.\n');
    exit(0);
  } else {
    print('❌ ${violations.length} violation(s) détectée(s):\n');

    // Grouper par type
    final byType = <String, List<DesignCenterViolation>>{};
    for (final v in violations) {
      byType.putIfAbsent(v.type, () => []).add(v);
    }

    for (final entry in byType.entries) {
      print('📍 ${entry.key}: ${entry.value.length} occurrence(s)');
      for (final v in entry.value) {
        print('   ${v.file}:${v.line}');
        print('   ⚠️  ${v.message}');
        print('   Code: ${v.code.trim()}');
        print('   💡 ${v.suggestion}\n');
      }
    }

    exit(1);
  }
}

List<DesignCenterViolation> _checkDurationHardcodes(
    String file, int line, String code) {
  final violations = <DesignCenterViolation>[];

  // Détecter Duration( avec valeurs hardcodées
  if (code.contains('Duration(') &&
      (code.contains('milliseconds:') || code.contains('seconds:'))) {
    // Vérifier qu'il n'utilise pas déjà une constante
    if (!code.contains('AppAnimations.') && !code.contains('const Duration')) {
      violations.add(DesignCenterViolation(
        file: file,
        line: line,
        type: 'Duration hardcodé',
        code: code,
        message: 'Utilisation de Duration() avec valeur hardcodée',
        suggestion:
            'Utiliser AppAnimations.fast/normal/slow/slower/slowest ou ajouter une nouvelle constante',
      ));
    }
  }

  return violations;
}

List<DesignCenterViolation> _checkEdgeInsetsHardcodes(
    String file, int line, String code) {
  final violations = <DesignCenterViolation>[];

  // Détecter EdgeInsets.* avec valeurs numériques
  final edgeInsetsPattern = RegExp(
      r'EdgeInsets\.(all|symmetric|only|fromLTRB)\s*\(\s*[\d.]+');

  if (edgeInsetsPattern.hasMatch(code)) {
    // Vérifier qu'il n'utilise pas déjà AppSpacing ou AppDimens
    if (!code.contains('AppSpacing.') &&
        !code.contains('AppDimens.') &&
        !code.contains('const EdgeInsets')) {
      violations.add(DesignCenterViolation(
        file: file,
        line: line,
        type: 'EdgeInsets hardcodé',
        code: code,
        message: 'Utilisation de EdgeInsets avec valeurs numériques hardcodées',
        suggestion:
            'Utiliser AppSpacing.buttonPadding*/cardPadding*/listItemPadding*/etc. ou AppDimens constants',
      ));
    }
  }

  return violations;
}

List<DesignCenterViolation> _checkSizedBoxHardcodes(
    String file, int line, String code) {
  final violations = <DesignCenterViolation>[];

  // Détecter SizedBox(height: ou width: avec valeurs numériques
  final sizedBoxPattern =
      RegExp(r'SizedBox\s*\(\s*(height|width):\s*[\d.]+');

  if (sizedBoxPattern.hasMatch(code)) {
    // Vérifier qu'il n'utilise pas déjà AppSpacing ou AppDimens
    if (!code.contains('AppSpacing.') && !code.contains('AppDimens.')) {
      violations.add(DesignCenterViolation(
        file: file,
        line: line,
        type: 'SizedBox hardcodé',
        code: code,
        message: 'Utilisation de SizedBox avec valeur hardcodée',
        suggestion:
            'Utiliser AppSpacing.gapS/M/L/Xl ou AppDimens constants',
      ));
    }
  }

  return violations;
}

List<DesignCenterViolation> _checkBoxShadowHardcodes(
    String file, int line, String code) {
  final violations = <DesignCenterViolation>[];

  // Détecter BoxShadow( avec valeurs hardcodées
  if (code.contains('BoxShadow(')) {
    // Vérifier qu'il n'utilise pas déjà AppElevations
    if (!code.contains('AppElevations.')) {
      violations.add(DesignCenterViolation(
        file: file,
        line: line,
        type: 'BoxShadow hardcodé',
        code: code,
        message: 'Utilisation de BoxShadow avec valeurs hardcodées',
        suggestion:
            'Utiliser AppElevations.none/sm/md/lg/xl ou colored()',
      ));
    }
  }

  return violations;
}

List<DesignCenterViolation> _checkOpacityHardcodes(
    String file, int line, String code) {
  final violations = <DesignCenterViolation>[];

  // Détecter withOpacity( ou withValues(alpha: avec valeurs numériques
  final opacityPattern =
      RegExp(r'(withOpacity|withValues)\s*\(\s*alpha:\s*[\d.]+');

  if (opacityPattern.hasMatch(code)) {
    // Vérifier qu'il n'utilise pas déjà AppOpacities
    if (!code.contains('AppOpacities.')) {
      violations.add(DesignCenterViolation(
        file: file,
        line: line,
        type: 'Opacity hardcodée',
        code: code,
        message: 'Utilisation de withOpacity/withValues avec valeur hardcodée',
        suggestion:
            'Utiliser AppOpacities.contentHigh/Medium/Low ou hoverOverlay/pressedOverlay',
      ));
    }
  }

  return violations;
}

List<DesignCenterViolation> _checkNumericSizeHardcodes(
    String file, int line, String code) {
  final violations = <DesignCenterViolation>[];

  // Détecter size: avec valeurs numériques dans Icon
  if (code.contains('Icon(') && code.contains('size:')) {
    final sizePattern = RegExp(r'size:\s*[\d.]+');
    if (sizePattern.hasMatch(code)) {
      // Vérifier qu'il n'utilise pas déjà AppComponentSizes
      if (!code.contains('AppComponentSizes.')) {
        violations.add(DesignCenterViolation(
          file: file,
          line: line,
          type: 'Icon size hardcodé',
          code: code,
          message: 'Utilisation de Icon size avec valeur hardcodée',
          suggestion:
              'Utiliser AppComponentSizes.iconSmall/Medium/Large/XLarge',
        ));
      }
    }
  }

  return violations;
}

List<DesignCenterViolation> _checkBorderRadiusHardcodes(
    String file, int line, String code) {
  final violations = <DesignCenterViolation>[];

  // Détecter BorderRadius.circular( avec valeurs numériques
  final borderRadiusPattern =
      RegExp(r'BorderRadius\.circular\s*\(\s*[\d.]+');

  if (borderRadiusPattern.hasMatch(code)) {
    // Vérifier qu'il n'utilise pas déjà AppDimens
    if (!code.contains('AppDimens.radius')) {
      violations.add(DesignCenterViolation(
        file: file,
        line: line,
        type: 'BorderRadius hardcodé',
        code: code,
        message: 'Utilisation de BorderRadius.circular avec valeur hardcodée',
        suggestion: 'Utiliser AppDimens.radiusS/M/L/Xl',
      ));
    }
  }

  return violations;
}

class DesignCenterViolation {
  final String file;
  final int line;
  final String type;
  final String code;
  final String message;
  final String suggestion;

  DesignCenterViolation({
    required this.file,
    required this.line,
    required this.type,
    required this.code,
    required this.message,
    required this.suggestion,
  });
}
