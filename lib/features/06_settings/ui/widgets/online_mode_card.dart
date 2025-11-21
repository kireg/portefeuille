import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';

class OnlineModeCard extends StatefulWidget {
  const OnlineModeCard({super.key});
  @override
  State<OnlineModeCard> createState() => _OnlineModeCardState();
}

class _OnlineModeCardState extends State<OnlineModeCard> {
  late TextEditingController _keyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey(SettingsProvider provider) async {
    final key = _keyController.text.trim();
    FocusScope.of(context).unfocus();
    await provider.setFmpApiKey(key);
    _keyController.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Clé mise à jour")));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(icon: Icons.cloud_outlined, color: AppColors.primary),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mode en ligne', style: AppTypography.h3),
                    Text('Prix temps réel', style: AppTypography.caption),
                  ],
                ),
              ),
              Switch(
                value: settings.isOnlineMode,
                onChanged: (val) => settings.toggleOnlineMode(val),
                activeColor: AppColors.primary,
              ),
            ],
          ),

          if (settings.isOnlineMode) ...[
            const SizedBox(height: AppDimens.paddingM),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimens.paddingM),

            Text('Clé API FMP (Optionnel)', style: AppTypography.bodyBold),
            const SizedBox(height: 8),
            Text(
                'Améliore la fiabilité des prix.',
                style: AppTypography.caption.copyWith(color: AppColors.textTertiary)
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      labelText: 'Clé API',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'OK',
                  onPressed: () => _saveKey(settings),
                  isFullWidth: false,
                  type: AppButtonType.secondary,
                ),
              ],
            ),
            if (settings.hasFmpApiKey)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text('Clé active', style: AppTypography.caption.copyWith(color: AppColors.success)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}