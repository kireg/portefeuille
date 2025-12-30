import 'dart:io';

/// Script pour auto-corriger TOUTES les violations Design Center
void main() async {
  print('🔧 Auto-fix ALL Design Center violations...\n');
  
  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    print('❌ Directory lib/ not found');
    exit(1);
  }

  int fixedCount = 0;
  final excludedPaths = [
    '\\generated\\',
    '\\.dart_tool\\',
    '\\app_spacing.dart', // Définitions légitimes
    '\\app_elevations.dart', // Définitions légitimes
    '\\app_opacities.dart',
    '\\app_dimens.dart',
    '\\app_component_sizes.dart',
  ];

  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      // Skip excluded paths
      if (excludedPaths.any((excluded) => file.path.contains(excluded))) {
        continue;
      }
      
      final content = await file.readAsString();
      String newContent = content;
      bool wasModified = false;
      
      // ===== ICON SIZE =====
      // Map all icon sizes to AppComponentSizes
      final iconSizeReplacements = {
        'size: 14': 'size: AppComponentSizes.iconXxSmall',
        'size: 16': 'size: AppComponentSizes.iconXSmall',
        'size: 18': 'size: AppComponentSizes.iconSmall',
        'size: 20': 'size: AppComponentSizes.iconMediumSmall',
        'size: 24': 'size: AppComponentSizes.iconMedium',
        'size: 28': 'size: AppComponentSizes.iconMediumLarge',
        'size: 32': 'size: AppComponentSizes.iconLarge',
        'size: 48': 'size: AppComponentSizes.iconXLarge',
        'size: 64': 'size: AppComponentSizes.iconXxLarge',
      };
      
      for (final entry in iconSizeReplacements.entries) {
        if (newContent.contains(entry.key)) {
          newContent = newContent.replaceAll(entry.key, entry.value);
          wasModified = true;
        }
      }
      
      // ===== BORDER RADIUS =====
      final radiusReplacements = {
        'BorderRadius.circular(6)': 'BorderRadius.circular(AppDimens.radius6)',
      };
      
      for (final entry in radiusReplacements.entries) {
        if (newContent.contains(entry.key)) {
          newContent = newContent.replaceAll(entry.key, entry.value);
          wasModified = true;
        }
      }
      
      // ===== SPECIAL SIZEDBOX =====
      final sizedBoxReplacements = {
        'const SizedBox(height: 2)': 'AppSpacing.gapTiny',
        'SizedBox(height: 2)': 'AppSpacing.gapTiny',
        'const SizedBox(width: 2)': 'AppSpacing.gapHTiny',
        'SizedBox(width: 2)': 'AppSpacing.gapHTiny',
        'const SizedBox(width: 4)': 'AppSpacing.gapH4',
        'SizedBox(width: 4)': 'AppSpacing.gapH4',
        'const SizedBox(width: 6)': 'AppSpacing.gapH6',
        'SizedBox(width: 6)': 'AppSpacing.gapH6',
        'const SizedBox(width: 10': 'AppSpacing.gapH10',
        'SizedBox(width: 10': 'AppSpacing.gapH10',
        'const SizedBox(height: 20)': 'AppSpacing.gap20',
        'SizedBox(height: 20)': 'AppSpacing.gap20',
        'const SizedBox(height: 40)': 'AppSpacing.gap40',
        'SizedBox(height: 40)': 'AppSpacing.gap40',
        'const SizedBox(height: 90': 'AppSpacing.gap90',
        'SizedBox(height: 90': 'AppSpacing.gap90',
        'const SizedBox(height: 100': 'AppSpacing.gap100',
        'SizedBox(height: 100': 'AppSpacing.gap100',
        'const SizedBox(width: 10, height: 10': 'AppSpacing.progressSmall',
        'SizedBox(width: 10, height: 10': 'AppSpacing.progressSmall',
      };
      
      for (final entry in sizedBoxReplacements.entries) {
        if (newContent.contains(entry.key)) {
          newContent = newContent.replaceAll(entry.key, entry.value);
          wasModified = true;
        }
      }
      
      // ===== OPACITY VALUES =====
      // Map withValues(alpha: X) to AppOpacities constants
      final opacityReplacements = {
        '.withValues(alpha: 0.0)': '.withValues(alpha: AppOpacities.transparent)',
        '.withValues(alpha: 0.05)': '.withValues(alpha: AppOpacities.subtle)',
        '.withValues(alpha: 0.1)': '.withValues(alpha: AppOpacities.lightOverlay)',
        '.withValues(alpha: 0.15)': '.withValues(alpha: AppOpacities.surfaceTint)',
        '.withValues(alpha: 0.2)': '.withValues(alpha: AppOpacities.border)',
        '.withValues(alpha: 0.3)': '.withValues(alpha: AppOpacities.decorative)',
        '.withValues(alpha: 0.4)': '.withValues(alpha: AppOpacities.shadow)',
        '.withValues(alpha: 0.5)': '.withValues(alpha: AppOpacities.semiVisible)',
        '.withValues(alpha: 0.6)': '.withValues(alpha: AppOpacities.prominent)',
        '.withValues(alpha: 0.7)': '.withValues(alpha: AppOpacities.strong)',
        '.withValues(alpha: 0.8)': '.withValues(alpha: AppOpacities.veryHigh)',
        '.withValues(alpha: 0.85)': '.withValues(alpha: AppOpacities.almostOpaque)',
        '.withValues(alpha: 0.9)': '.withValues(alpha: AppOpacities.nearFull)',
        // Also handle withOpacity
        '.withOpacity(0.0)': '.withValues(alpha: AppOpacities.transparent)',
        '.withOpacity(0.05)': '.withValues(alpha: AppOpacities.subtle)',
        '.withOpacity(0.1)': '.withValues(alpha: AppOpacities.lightOverlay)',
        '.withOpacity(0.15)': '.withValues(alpha: AppOpacities.surfaceTint)',
        '.withOpacity(0.2)': '.withValues(alpha: AppOpacities.border)',
        '.withOpacity(0.3)': '.withValues(alpha: AppOpacities.decorative)',
        '.withOpacity(0.4)': '.withValues(alpha: AppOpacities.shadow)',
        '.withOpacity(0.5)': '.withValues(alpha: AppOpacities.semiVisible)',
        '.withOpacity(0.6)': '.withValues(alpha: AppOpacities.prominent)',
        '.withOpacity(0.7)': '.withValues(alpha: AppOpacities.strong)',
        '.withOpacity(0.8)': '.withValues(alpha: AppOpacities.veryHigh)',
        '.withOpacity(0.85)': '.withValues(alpha: AppOpacities.almostOpaque)',
        '.withOpacity(0.9)': '.withValues(alpha: AppOpacities.nearFull)',
      };
      
      for (final entry in opacityReplacements.entries) {
        if (newContent.contains(entry.key)) {
          newContent = newContent.replaceAll(entry.key, entry.value);
          wasModified = true;
        }
      }
      
      if (wasModified) {
        await file.writeAsString(newContent);
        fixedCount++;
        print('✅ Fixed: ${file.path}');
      }
    }
  }

  print('\n✨ Fixed $fixedCount file(s)');
  print('🔍 Run the compliance checker again to verify');
}
