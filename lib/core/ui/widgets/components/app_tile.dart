import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';

class AppTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;     // Souvent un AppIcon
  final Widget? trailing;    // Montant ou flèche
  final VoidCallback? onTap;
  final bool isDestructive;  // Pour les actions "Supprimer"

  const AppTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingS,
            vertical: AppDimens.paddingM,
          ),
          child: Row(
            children: [
              // 1. Leading (Icône)
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppDimens.paddingM),
              ],

              // 2. Textes (Titre + Sous-titre)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyBold.copyWith(
                        color: isDestructive
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Trailing (Valeur ou Action)
              if (trailing != null) ...[
                const SizedBox(width: AppDimens.paddingM),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}