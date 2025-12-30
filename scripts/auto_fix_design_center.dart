import 'dart:io';

/// Script pour auto-corriger les violations Design Center détectées
void main() async {
  print('🔧 Auto-fix Design Center violations...\n');
  
  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    print('❌ Directory lib/ not found');
    exit(1);
  }

  int fixedCount = 0;

  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      if (file.path.contains('\\generated\\') || 
          file.path.contains('\\.dart_tool\\')) {
        continue;
      }
      
      final content = await file.readAsString();
      String newContent = content;
      
      // Fix SizedBox height values
      newContent = newContent.replaceAll('const SizedBox(height: 4)', 'AppSpacing.gapXs');
      newContent = newContent.replaceAll('SizedBox(height: 4)', 'AppSpacing.gapXs');
      newContent = newContent.replaceAll('const SizedBox(height: 8)', 'AppSpacing.gapS');
      newContent = newContent.replaceAll('SizedBox(height: 8)', 'AppSpacing.gapS');
      newContent = newContent.replaceAll('const SizedBox(height: 12)', 'AppSpacing.gap12');
      newContent = newContent.replaceAll('SizedBox(height: 12)', 'AppSpacing.gap12');
      newContent = newContent.replaceAll('const SizedBox(height: 16)', 'AppSpacing.gapM');
      newContent = newContent.replaceAll('SizedBox(height: 16)', 'AppSpacing.gapM');
      newContent = newContent.replaceAll('const SizedBox(height: 24)', 'AppSpacing.gapL');
      newContent = newContent.replaceAll('SizedBox(height: 24)', 'AppSpacing.gapL');
      newContent = newContent.replaceAll('const SizedBox(height: 32)', 'AppSpacing.gapXl');
      newContent = newContent.replaceAll('SizedBox(height: 32)', 'AppSpacing.gapXl');
      newContent = newContent.replaceAll('const SizedBox(height: 48)', 'AppSpacing.gapXxl');
      newContent = newContent.replaceAll('SizedBox(height: 48)', 'AppSpacing.gapXxl');
      
      // Fix SizedBox width values
      newContent = newContent.replaceAll('const SizedBox(width: 8)', 'AppSpacing.gapHorizontalSmall');
      newContent = newContent.replaceAll('SizedBox(width: 8)', 'AppSpacing.gapHorizontalSmall');
      newContent = newContent.replaceAll('const SizedBox(width: 12)', 'AppSpacing.gapH12');
      newContent = newContent.replaceAll('SizedBox(width: 12)', 'AppSpacing.gapH12');
      newContent = newContent.replaceAll('const SizedBox(width: 16)', 'AppSpacing.gapHorizontalMedium');
      newContent = newContent.replaceAll('SizedBox(width: 16)', 'AppSpacing.gapHorizontalMedium');
      newContent = newContent.replaceAll('const SizedBox(width: 24)', 'AppSpacing.gapHorizontalLarge');
      newContent = newContent.replaceAll('SizedBox(width: 24)', 'AppSpacing.gapHorizontalLarge');
      newContent = newContent.replaceAll('const SizedBox(width: 48)', 'AppSpacing.gapHXxl');
      newContent = newContent.replaceAll('SizedBox(width: 48)', 'AppSpacing.gapHXxl');
      
      // Fix EdgeInsets.all(16.0)
      newContent = newContent.replaceAll('padding: EdgeInsets.all(16.0)', 'padding: AppSpacing.paddingAll16');
      
      // Fix BorderRadius.circular common values
      newContent = newContent.replaceAll('borderRadius: BorderRadius.circular(2)', 'borderRadius: BorderRadius.circular(AppDimens.radiusXs)');
      newContent = newContent.replaceAll('borderRadius: BorderRadius.circular(4)', 'borderRadius: BorderRadius.circular(AppDimens.radiusXs2)');
      newContent = newContent.replaceAll('borderRadius: BorderRadius.circular(8)', 'borderRadius: BorderRadius.circular(AppDimens.radiusS)');
      newContent = newContent.replaceAll('borderRadius: BorderRadius.circular(10)', 'borderRadius: BorderRadius.circular(AppDimens.radius10)');
      newContent = newContent.replaceAll('borderRadius: BorderRadius.circular(12)', 'borderRadius: BorderRadius.circular(AppDimens.radius12)');
      newContent = newContent.replaceAll('borderRadius: BorderRadius.circular(16)', 'borderRadius: BorderRadius.circular(AppDimens.radiusM)');
      newContent = newContent.replaceAll('borderRadius: BorderRadius.circular(20)', 'borderRadius: BorderRadius.circular(AppDimens.radius20)');
      newContent = newContent.replaceAll('borderRadius: BorderRadius.circular(24)', 'borderRadius: BorderRadius.circular(AppDimens.radiusL)');
      newContent = newContent.replaceAll('borderRadius: BorderRadius.circular(30)', 'borderRadius: BorderRadius.circular(AppDimens.radius30)');
      newContent = newContent.replaceAll('borderRadius: BorderRadius.circular(32)', 'borderRadius: BorderRadius.circular(AppDimens.radius32)');
      
      if (newContent != content) {
        await file.writeAsString(newContent);
        fixedCount++;
        print('✅ Fixed: ${file.path}');
      }
    }
  }

  print('\n✨ Fixed $fixedCount file(s)');
  print('🔍 Run the compliance checker again to see remaining violations');
}
