import 'dart:io';

void main() async {
  print('🔧 Adding missing imports to all Dart files...\n');

  // Map of class name to relative import path from lib/
  final Map<String, String> classToImport = {
    'AppOpacities': "import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';",
    'AppComponentSizes': "import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';",
    'AppSpacing': "import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';",
    'AppDimens': "import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';",
  };

  int fixedCount = 0;

  // Recursively find all dart files
  final dartFiles = await Directory('lib')
      .list(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  for (final file in dartFiles) {
    final content = await file.readAsString();
    final lines = content.split('\n');

    // Check which classes are used
    final usedClasses = <String>{};
    for (final className in classToImport.keys) {
      if (content.contains('$className.') || content.contains('const $className(')) {
        usedClasses.add(className);
      }
    }

    if (usedClasses.isEmpty) continue;

    // Check which imports are missing
    final missingImports = <String>[];
    for (final className in usedClasses) {
      final importLine = classToImport[className]!;
      if (!content.contains(importLine)) {
        missingImports.add(importLine);
      }
    }

    if (missingImports.isEmpty) continue;

    // Find insertion point - after last import
    int insertIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('import ')) {
        insertIndex = i + 1;
      }
    }

    if (insertIndex == -1) {
      print('⚠️  No imports found in: ${file.path}');
      continue;
    }

    // Insert missing imports
    for (final importLine in missingImports.reversed) {
      lines.insert(insertIndex, importLine);
    }

    // Write back
    await file.writeAsString(lines.join('\n'));
    fixedCount++;
    print('✅ ${file.path} (added ${missingImports.length} import(s))');
  }

  print('\n✨ Fixed $fixedCount file(s)');
}
