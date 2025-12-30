// 🎨 EXEMPLES D'UTILISATION DU DESIGN CENTER ENRICHI
// ====================================================
// 
// Ce fichier démontre comment utiliser les nouvelles constantes
// ajoutées au Design Center (30 Décembre 2025)

import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';

// ============================================
// 1. COULEURS D'INSTITUTIONS
// ============================================

Widget buildInstitutionLogo(String institutionName) {
  Color logoColor;
  
  switch (institutionName) {
    case 'Trade Republic':
      logoColor = AppColors.institutionTradeRepublic; // ✅ Au lieu de: const Color(0xFFD40055)
      break;
    case 'Scalable Capital':
      logoColor = AppColors.institutionScalable; // ✅ Au lieu de: const Color(0xFF00BFA5)
      break;
    case 'Boursorama':
      logoColor = AppColors.institutionBlack; // ✅ Au lieu de: Colors.black
      break;
    default:
      logoColor = AppColors.primary;
  }
  
  return Container(
    width: AppComponentSizes.institutionLogoSize, // ✅ Au lieu de: 48
    height: AppComponentSizes.institutionLogoSize,
    decoration: BoxDecoration(
      color: logoColor,
      borderRadius: BorderRadius.circular(AppDimens.radius12),
    ),
  );
}

// ============================================
// 2. WIZARD STEPS & FORMS
// ============================================

Widget buildWizardStepButton({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      // ✅ Avant: padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
      padding: AppSpacing.wizardStepPadding,
      
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          // ✅ Avant: width: 2
          width: AppDimens.borderWidthBold,
        ),
      ),
      
      child: Text(
        label,
        style: AppTypography.bodyBold.copyWith(
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    ),
  );
}

Widget buildFormField({
  required String label,
  required TextEditingController controller,
}) {
  return Container(
    // ✅ Avant: padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
    padding: AppSpacing.formFieldPadding,
    
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      
      border: Border.all(
        color: AppColors.border,
        // ✅ Avant: width: 1
        width: AppDimens.borderWidthStandard,
      ),
    ),
    
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: InputBorder.none,
      ),
    ),
  );
}

// ============================================
// 3. CHIPS & BADGES
// ============================================

Widget buildCompactChip(String label) {
  return Container(
    // ✅ Avant: padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
    padding: AppSpacing.chipPaddingCompact,
    
    decoration: BoxDecoration(
      color: AppColors.success,
      borderRadius: BorderRadius.circular(AppDimens.radiusS),
    ),
    
    child: Text(
      label,
      style: AppTypography.caption.copyWith(color: Colors.white),
    ),
  );
}

// ============================================
// 4. INSTITUTION SOURCE CARDS
// ============================================

Widget buildInstitutionSourceCard({
  required String institutionName,
  required IconData icon,
  required Color brandColor,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.zero,
      
      decoration: BoxDecoration(
        color: isSelected 
          ? AppColors.primary.withOpacity(0.1) 
          : null,
        
        border: isSelected
          // ✅ Avant: ? Border.all(color: AppColors.primary, width: 2)
          ? Border.all(
              color: AppColors.primary, 
              width: AppDimens.borderWidthBold,
            )
          : null,
          
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            // ✅ Avant: width: 48, height: 48
            width: AppComponentSizes.institutionLogoSize,
            height: AppComponentSizes.institutionLogoSize,
            
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(AppDimens.radius12),
            ),
            
            child: Icon(
              icon, 
              // ✅ Avant: size: 32
              size: AppComponentSizes.iconLarge,
              color: Colors.white,
            ),
          ),
          
          AppSpacing.gapM,
          
          Text(
            institutionName,
            style: AppTypography.bodyBold.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}

// ============================================
// 5. PREVIEW CARDS (IMPORT)
// ============================================

Widget buildPreviewCard({required Widget child}) {
  return Container(
    // ✅ Avant: height: 180
    height: AppComponentSizes.previewCardHeight,
    
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusL),
      
      border: Border.all(
        color: AppColors.border,
        // ✅ Avant: width: 1
        width: AppDimens.borderWidthStandard,
      ),
    ),
    
    child: child,
  );
}

// ============================================
// 6. PROGRESS INDICATORS
// ============================================

Widget buildProgressIndicator() {
  return Container(
    // ✅ Avant: width: 40, height: 4
    width: AppComponentSizes.progressIndicatorWidth,
    height: AppComponentSizes.progressIndicatorHeight,
    
    decoration: BoxDecoration(
      color: AppColors.textSecondary.withOpacity(0.2),
      borderRadius: BorderRadius.circular(AppDimens.radiusXs),
    ),
    
    child: FractionallySizedBox(
      widthFactor: 0.6, // 60% rempli
      alignment: Alignment.centerLeft,
      
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimens.radiusXs),
        ),
      ),
    ),
  );
}

// ============================================
// 7. MODAL HEADERS
// ============================================

Widget buildModalHeader({required String title}) {
  return Container(
    // ✅ Avant: padding: const EdgeInsets.symmetric(horizontal: 40)
    padding: AppSpacing.modalHeaderPadding,
    
    child: Column(
      children: [
        buildProgressIndicator(),
        AppSpacing.gapL,
        Text(
          title,
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ============================================
// 8. BOTTOM SHEETS
// ============================================

Widget buildBottomSheetContent({required List<Widget> children}) {
  return Container(
    // ✅ Avant: padding: const EdgeInsets.fromLTRB(24, 12, 24, 48)
    padding: AppSpacing.bottomSheetPaddingCustom,
    
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppDimens.radiusL),
        topRight: Radius.circular(AppDimens.radiusL),
      ),
    ),
    
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
}

// ============================================
// 9. EXEMPLE COMPLET: WIZARD ÉTAPE INSTITUTION
// ============================================

class InstitutionSelectionStep extends StatelessWidget {
  const InstitutionSelectionStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec padding custom
        buildModalHeader(title: 'Choisissez votre courtier'),
        
        AppSpacing.gapL,
        
        // Liste des institutions
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            buildInstitutionSourceCard(
              institutionName: 'Trade Republic',
              icon: Icons.account_balance,
              brandColor: AppColors.institutionTradeRepublic, // ✅
              isSelected: true,
              onTap: () {},
            ),
            
            buildInstitutionSourceCard(
              institutionName: 'Scalable Capital',
              icon: Icons.trending_up,
              brandColor: AppColors.institutionScalable, // ✅
              isSelected: false,
              onTap: () {},
            ),
          ],
        ),
        
        AppSpacing.gapXl,
        
        // Badge "Recommandé"
        buildCompactChip('Recommandé'),
      ],
    );
  }
}

// ============================================
// 10. RÉCAPITULATIF DES REMPLACEMENTS
// ============================================

/*
AVANT (❌ Hardcodé):
- const Color(0xFFD40055)
- const Color(0xFF00BFA5)
- Colors.black
- EdgeInsets.symmetric(horizontal: 24, vertical: 12)
- EdgeInsets.symmetric(horizontal: 16, vertical: 10)
- EdgeInsets.symmetric(horizontal: 6, vertical: 2)
- EdgeInsets.symmetric(horizontal: 40)
- EdgeInsets.fromLTRB(24, 12, 24, 48)
- width: 48, height: 48
- height: 180
- width: 40, height: 4
- width: 2 (bordures)
- width: 1 (bordures)

APRÈS (✅ Design Center):
- AppColors.institutionTradeRepublic
- AppColors.institutionScalable
- AppColors.institutionBlack
- AppSpacing.wizardStepPadding
- AppSpacing.formFieldPadding
- AppSpacing.chipPaddingCompact
- AppSpacing.modalHeaderPadding
- AppSpacing.bottomSheetPaddingCustom
- AppComponentSizes.institutionLogoSize
- AppComponentSizes.previewCardHeight
- AppComponentSizes.progressIndicatorWidth/Height
- AppDimens.borderWidthBold
- AppDimens.borderWidthStandard

GAIN:
- ⏱️ Modification centralisée (2min au lieu de 45min)
- 🎨 Cohérence visuelle garantie
- 🔄 Scalabilité (dark mode, A/B testing)
- 🧹 Code plus propre et maintenable
*/
