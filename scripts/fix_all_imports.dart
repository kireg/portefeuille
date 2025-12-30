import 'dart:io';

void main() {
  print('🔧 Fixing all missing imports...\n');

  // Map de fichiers et leurs imports manquants
  final Map<String, Set<String>> filesToFix = {
    // Core
    'lib/core/ui/theme/app_theme.dart': {'AppOpacities'},
    'lib/core/ui/theme/app_colors.dart': {'AppOpacities'},
    'lib/core/ui/widgets/components/app_floating_nav_bar.dart': {'AppOpacities', 'AppComponentSizes'},
    'lib/core/ui/widgets/components/app_animated_background.dart': {'AppOpacities'},
    'lib/core/ui/widgets/primitives/app_button.dart': {'AppOpacities'},
    'lib/core/ui/widgets/inputs/app_text_field.dart': {'AppComponentSizes'},
    'lib/core/ui/widgets/inputs/app_dropdown.dart': {'AppComponentSizes'},
    
    // Features 01
    'lib/features/01_launch/ui/launch_screen.dart': {'AppSpacing'},
    
    // Features 05
    'lib/features/05_planner/ui/widgets/savings_plans_section.dart': {'AppSpacing'},
    'lib/features/05_planner/ui/widgets/projection_section.dart': {'AppSpacing'},
    'lib/features/05_planner/ui/widgets/crowdfunding_planner_widget.dart': {'AppSpacing'},
    'lib/features/05_planner/ui/widgets/crowdfunding_timeline_widget.dart': {'AppSpacing'},
    'lib/features/05_planner/ui/widgets/crowdfunding_map_widget.dart': {'AppSpacing'},
    'lib/features/05_planner/ui/widgets/crowdfunding_projection_chart.dart': {'AppSpacing'},
    'lib/features/05_planner/ui/widgets/crowdfunding_summary_cards.dart': {'AppSpacing'},
    
    // Features 06
    'lib/features/06_settings/ui/widgets/online_mode_card.dart': {'AppSpacing'},
    'lib/features/06_settings/ui/widgets/danger_zone_card.dart': {'AppSpacing', 'AppOpacities', 'AppDimens', 'AppComponentSizes'},
    
    // Features 07
    'lib/features/07_management/ui/screens/add_savings_plan_screen.dart': {'AppSpacing', 'AppOpacities', 'AppComponentSizes'},
    
    // Features 09
    'lib/features/09_imports/ui/screens/import_hub_screen.dart': {'AppSpacing', 'AppDimens'},
    'lib/features/09_imports/ui/screens/ai_import_config_screen.dart': {'AppSpacing'},
    'lib/features/09_imports/ui/screens/file_import_wizard/wizard_header.dart': {'AppSpacing', 'AppDimens'},
    'lib/features/09_imports/ui/screens/file_import_wizard/wizard_footer.dart': {'AppSpacing'},
    'lib/features/09_imports/ui/screens/file_import_wizard/wizard_candidate_card.dart': {'AppSpacing', 'AppDimens'},
    'lib/features/09_imports/ui/widgets/transaction_edit_dialog.dart': {'AppSpacing'},
  };

  int fixedCount = 0;
  
  for (final entry in filesToFix.entries) {
    final filePath = entry.key;
    final importsToAdd = entry.value;
    
    final file = File(filePath);
    if (!file.existsSync()) {
      print('⚠️  File not found: $filePath');
      continue;
    }
    
    final lines = file.readAsLinesSync();
    final importsToInsert = <String>[];
    
    // Check what imports are already there
    for (final importName in importsToAdd) {
      final importLine = _getImportLine(importName);
      final alreadyHasImport = lines.any((line) => line.contains(importLine.substring(8, importLine.length - 2))); // Remove "import '" and "';"
      
      if (!alreadyHasImport) {
        importsToInsert.add(importLine);
      }
    }
    
    if (importsToInsert.isEmpty) {
      continue;
    }
    
    // Find insertion point (after last theme import or after last import)
    int insertIndex = -1;
    for (int i = lines.length - 1; i >= 0; i--) {
      if (lines[i].startsWith("import '../../") || 
          lines[i].startsWith("import '../") ||
          lines[i].startsWith("import 'package:")) {
        insertIndex = i + 1;
        break;
      }
    }
    
    if (insertIndex == -1) {
      print('⚠️  Could not find insertion point in: $filePath');
      continue;
    }
    
    // Insert imports
    for (final importLine in importsToInsert.reversed) {
      lines.insert(insertIndex, importLine);
    }
    
    // Write back
    file.writeAsStringSync(lines.join('\n'));
    fixedCount++;
    print('✅ Fixed: $filePath (added ${importsToInsert.length} import(s))');
  }
  
  print('\n✨ Fixed $fixedCount file(s)');
}

String _getImportLine(String className) {
  switch (className) {
    case 'AppOpacities':
      return "import '../../../core/ui/theme/app_opacities.dart';";
    case 'AppComponentSizes':
      return "import '../../../core/ui/theme/app_component_sizes.dart';";
    case 'AppSpacing':
      return "import '../../../core/ui/theme/app_spacing.dart';";
    case 'AppDimens':
      return "import '../../../core/ui/theme/app_dimens.dart';";
    default:
      throw Exception('Unknown class: $className');
  }
}
