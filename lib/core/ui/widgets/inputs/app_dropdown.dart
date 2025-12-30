import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;
  final bool isExpanded;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimens.paddingS),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          isExpanded: isExpanded,
          // --- Personnalisation du menu (Popup) ---
          dropdownColor: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusS), // Arrondis du menu
          elevation: 4, // Ombre plus douce (8 par défaut)
          menuMaxHeight: 300, // Limite la hauteur pour éviter de couvrir tout l'écran
          // ----------------------------------------
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingM,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary, size: AppComponentSizes.iconMediumSmall)
                : null,
            border: _buildBorder(AppColors.border),
            enabledBorder: _buildBorder(AppColors.border),
            focusedBorder: _buildBorder(AppColors.primary),
            errorBorder: _buildBorder(AppColors.error),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.radiusS),
      borderSide: BorderSide(color: color, width: 1),
    );
  }
}