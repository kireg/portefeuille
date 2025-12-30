import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_component_sizes.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final String? suffixText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool autofocus;
  final VoidCallback? onTap;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final String? errorText;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixText,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.obscureText = false,
    this.autofocus = false,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label hors du champ pour un style plus aéré
        Text(
          label.toUpperCase(),
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimens.paddingS),

        TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          cursorColor: AppColors.primary,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          obscureText: obscureText,
          autofocus: autofocus,
          onTap: onTap,
          readOnly: readOnly,
          onChanged: onChanged,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.all(AppDimens.paddingM),

            // Préfixe Icône
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary, size: AppComponentSizes.iconMediumSmall)
                : null,

            // Suffixe (Texte ou Widget)
            suffixText: suffixText,
            suffixStyle: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary),
            suffixIcon: suffixIcon,

            // Bordures
            border: _buildBorder(AppColors.border),
            enabledBorder: _buildBorder(AppColors.border),
            focusedBorder: _buildBorder(AppColors.primary), // Glow au focus
            errorBorder: _buildBorder(AppColors.error),
            focusedErrorBorder: _buildBorder(AppColors.error),
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