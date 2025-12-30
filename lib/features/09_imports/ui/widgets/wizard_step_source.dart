import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/09_imports/services/models/import_category.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';

class WizardStepSource extends StatelessWidget {
  final String? selectedSourceId;
  final ValueChanged<String> onSelectSource;
  final ImportMode importMode;
  final ValueChanged<ImportMode> onImportModeChanged;
  final ImportCategory trCategory;
  final ValueChanged<ImportCategory> onTrCategoryChanged;
  final String? suggestedSourceId;
  final double? suggestionConfidence;

  const WizardStepSource({
    super.key,
    required this.selectedSourceId,
    required this.onSelectSource,
    required this.importMode,
    required this.onImportModeChanged,
    required this.trCategory,
    required this.onTrCategoryChanged,
    this.suggestedSourceId,
    this.suggestionConfidence,
  });

  @override
  Widget build(BuildContext context) {
    final sources = [
      _SourceOption(
        id: 'boursorama',
        name: 'Boursobanque',
        assetPath: 'assets/logos/boursorama.png',
        color: const Color(0xFFD40055),
      ),
      _SourceOption(
        id: 'revolut',
        name: 'Revolut',
        assetPath: 'assets/logos/revolut.png',
        color: Colors.black,
      ),
      _SourceOption(
        id: 'trade_republic',
        name: 'Trade Republic',
        assetPath: 'assets/logos/trade_republic.png',
        color: Colors.black,
      ),
      _SourceOption(
        id: 'la_premiere_brique',
        name: 'La Première Brique',
        icon: Icons.apartment,
        color: const Color(0xFF00BFA5),
      ),
      _SourceOption(
        id: 'other_ai',
        name: 'Autre (IA)',
        icon: Icons.auto_awesome,
        color: AppColors.accent,
        isSpecial: true,
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quelle est la source ?',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapS,
          Text(
            'Sélectionnez l\'institution d\'origine du fichier.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (suggestedSourceId != null && suggestionConfidence != null) ...[
            AppSpacing.gap12,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: AppOpacities.lightOverlay),
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                border: Border.all(color: AppColors.success.withValues(alpha: AppOpacities.decorative)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.success, size: AppComponentSizes.iconSmall),
                  AppSpacing.gapHorizontalSmall,
                  Text(
                    'Source suggérée : ${_getSourceName(suggestedSourceId!)} '
                    '(${(suggestionConfidence! * 100).toInt()}%)',
                    style: AppTypography.bodyBold.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
          AppSpacing.gapL,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              final isSelected = selectedSourceId == source.id;

              return _buildSourceCard(source, isSelected);
            },
          ),
          AppSpacing.gapM,
          _buildImportModeSelector(),
          if (selectedSourceId == 'trade_republic') ...[
            AppSpacing.gapM,
            _buildTrCategorySelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildImportModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode d\'import', style: AppTypography.h3),
        AppSpacing.gap12,
        Center(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: ImportMode.values.map((mode) {
              final isSelected = importMode == mode;
              final label =
                  mode == ImportMode.initial ? 'Initial' : 'Actualisation';
              return InkWell(
                onTap: () => onImportModeChanged(mode),
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary 
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.primary 
                          : AppColors.border,
                      width: 2,
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
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTrCategorySelector() {
    const labels = {
      ImportCategory.crypto: 'Crypto',
      ImportCategory.pea: 'PEA',
      ImportCategory.cto: 'CTO',
      ImportCategory.unknown: 'Inconnu',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Données Trade Republic à importer', style: AppTypography.h3),
        AppSpacing.gap12,
        Center(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: labels.entries.map((entry) {
              final isSelected = trCategory == entry.key;
              return InkWell(
                onTap: () => onTrCategoryChanged(entry.key),
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary 
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.primary 
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: AppTypography.bodyBold.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceCard(_SourceOption source, bool isSelected) {
    final isSuggested = suggestedSourceId == source.id;
    
    return Stack(
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          onTap: () => onSelectSource(source.id),
          backgroundColor:
              isSelected ? AppColors.primary.withValues(alpha: AppOpacities.lightOverlay) : null,
          child: Container(
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : isSuggested
                      ? Border.all(color: AppColors.success.withValues(alpha: AppOpacities.semiVisible), width: 2)
                      : null,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (source.assetPath != null)
                  Image.asset(
                    source.assetPath!,
                    width: 48,
                    height: 48,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.account_balance, size: AppComponentSizes.iconXLarge, color: source.color),
                  )
                else
                  Icon(source.icon, size: AppComponentSizes.iconXLarge, color: source.color),
                AppSpacing.gapM,
                Text(
                  source.name,
                  style: AppTypography.h3.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (isSuggested && !isSelected)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: const Text(
                '✨',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  String _getSourceName(String sourceId) {
    const names = {
      'boursorama': 'Boursobanque',
      'revolut': 'Revolut',
      'trade_republic': 'Trade Republic',
      'la_premiere_brique': 'La Première Brique',
    };
    return names[sourceId] ?? sourceId;
  }
}

class _SourceOption {
  final String id;
  final String name;
  final String? assetPath;
  final IconData? icon;
  final Color color;
  final bool isSpecial;

  _SourceOption({
    required this.id,
    required this.name,
    this.assetPath,
    this.icon,
    required this.color,
    this.isSpecial = false,
  });
}
