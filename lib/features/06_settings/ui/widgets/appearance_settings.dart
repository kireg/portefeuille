// lib/features/06_settings/ui/widgets/appearance_settings.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

// Liste des couleurs prédéfinies - Utilise AppColors + palette personnalisée
final List<Color> _colorOptions = [
  AppColors.primary,     // Bleu principal
  AppColors.accent,      // Violet secondaire
  AppColors.cyan,        // Cyan
  AppColors.success,     // Vert
  AppColors.warning,     // Orange/Ambre
  AppColors.error,       // Rouge
];

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Couleur principale',
          style: theme.textTheme.titleMedium,
        ),
        AppSpacing.gapS,
        Text(
          'Cette couleur sera utilisée pour les boutons, les icônes et les éléments actifs de l\'interface.',
          style: AppTypography.caption,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center( // Centrer les options
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16.0, // Plus d'espace
              runSpacing: 16.0,
              children: _colorOptions.map((color) {
                return _buildColorChip(
                    context, color, settingsProvider.appColor == color);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorChip(
      BuildContext context, Color color, bool isSelected) {
    return _ColorChip(
      color: color,
      isSelected: isSelected,
      onTap: () {
        Provider.of<SettingsProvider>(context, listen: false).setAppColor(color);
      },
    );
  }
}

class _ColorChip extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ColorChip> createState() => _ColorChipState();
}

class _ColorChipState extends State<_ColorChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isSelected || _isHovered ? 48 : 40,
          height: widget.isSelected || _isHovered ? 48 : 40,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSelected ? AppColors.white : Colors.transparent,
              width: widget.isSelected ? 4 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: AppOpacities.shadow),
                blurRadius: widget.isSelected || _isHovered ? 12 : 4,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: widget.isSelected
              ? const Icon(Icons.check, color: AppColors.white, size: AppComponentSizes.iconMedium)
              : null,
        ),
      ),
    );
  }
}