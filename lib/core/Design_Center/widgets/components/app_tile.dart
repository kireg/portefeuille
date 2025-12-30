import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';

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
          padding: AppSpacing.tilePaddingDefault,
          child: Row(
            children: [
              // 1. Leading (Icône)
              if (leading != null) ...[
                leading!,
                AppSpacing.gapM,
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
                      AppSpacing.gapTiny,
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
                AppSpacing.gapM,
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}