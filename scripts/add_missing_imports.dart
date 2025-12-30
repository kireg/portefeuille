import 'dart:io';

/// Script pour ajouter les imports AppOpacities et AppComponentSizes manquants
void main() async {
  print('🔧 Adding missing imports...\n');
  
  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    print('❌ Directory lib/ not found');
    exit(1);
  }

  int fixedCount = 0;

  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      if (file.path.contains('\\generated\\') || 
          file.path.contains('\\.dart_tool\\') ||
          file.path.contains('\\app_opacities.dart') ||
          file.path.contains('\\app_component_sizes.dart')) {
        continue;
      }
      
      final content = await file.readAsString();
      
      // Check if file uses AppOpacities or AppComponentSizes
      final usesOpacities = content.contains('AppOpacities.');
      final usesComponentSizes = content.contains('AppComponentSizes.');
      
      if (!usesOpacities && !usesComponentSizes) {
        continue; // No need to add imports
      }
      
      // Check if imports are already present
      final hasOpacitiesImport = content.contains("import 'package:portefeuille/core/ui/theme/app_opacities.dart'");
      final hasComponentSizesImport = content.contains("import 'package:portefeuille/core/ui/theme/app_component_sizes.dart'");
      
      bool needsModification = false;
      String newContent = content;
      
      // Find the last theme import to insert after it
      final themeImportPattern = RegExp(r"import 'package:portefeuille/core/ui/theme/(app_\w+)\.dart';");
      final matches = themeImportPattern.allMatches(content).toList();
      
      if (matches.isEmpty) {
        // No theme imports found, skip this file
        continue;
      }
      
      final lastThemeImport = matches.last;
      final insertPosition = lastThemeImport.end;
      
      String importsToAdd = '';
      
      if (usesOpacities && !hasOpacitiesImport) {
        importsToAdd += "\nimport 'package:portefeuille/core/ui/theme/app_opacities.dart';";
        needsModification = true;
      }
      
      if (usesComponentSizes && !hasComponentSizesImport) {
        importsToAdd += "\nimport 'package:portefeuille/core/ui/theme/app_component_sizes.dart';";
        needsModification = true;
      }
      
      if (needsModification) {
        newContent = content.substring(0, insertPosition) + 
                     importsToAdd +
                     content.substring(insertPosition);
        
        await file.writeAsString(newContent);
        fixedCount++;
        print('✅ Added imports to: ${file.path}');
      }
    }
  }

  print('\n✨ Fixed $fixedCount file(s)');
}
