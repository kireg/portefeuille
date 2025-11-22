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
  late TextEditingController _fmpKeyController;
  late TextEditingController _geminiKeyController;
  bool _obscureFmpKey = true;
  bool _obscureGeminiKey = true;

  @override
  void initState() {
    super.initState();
    _fmpKeyController = TextEditingController();
    _geminiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _fmpKeyController.dispose();
    _geminiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveFmpKey(SettingsProvider provider) async {
    final key = _fmpKeyController.text.trim();
    FocusScope.of(context).unfocus();
    await provider.setFmpApiKey(key);
    _fmpKeyController.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Clé FMP mise à jour")));
  }

  Future<void> _saveGeminiKey(SettingsProvider provider) async {
    final key = _geminiKeyController.text.trim();
    FocusScope.of(context).unfocus();
    await provider.setGeminiApiKey(key);
    _geminiKeyController.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Clé Gemini mise à jour")));
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
                    Text('Services Connectés', style: AppTypography.h3),
                    Text('IA & Données boursières', style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.paddingM),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimens.paddingM),

          // --- SECTION GEMINI (IA) ---
          Text('Intelligence Artificielle (Gemini)', style: AppTypography.bodyBold),
          const SizedBox(height: 8),
          Text(
              'Permet l\'analyse de PDF pour les transactions.',
              style: AppTypography.caption.copyWith(color: AppColors.textTertiary)
          ),
          const SizedBox(height: 12),
          if (settings.hasGeminiApiKey)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                  const SizedBox(width: 4),
                  Text('Clé active', style: AppTypography.caption.copyWith(color: AppColors.success)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _geminiKeyController,
                  obscureText: _obscureGeminiKey,
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    labelText: 'Clé API Gemini',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureGeminiKey ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscureGeminiKey = !_obscureGeminiKey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: 'OK',
                onPressed: () => _saveGeminiKey(settings),
                isFullWidth: false,
                type: AppButtonType.secondary,
              ),
            ],
          ),

          const SizedBox(height: AppDimens.paddingXL),

          // --- SECTION FMP (Existing) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Données Boursières (FMP)', style: AppTypography.bodyBold),
              Switch(
                value: settings.isOnlineMode,
                onChanged: (val) => settings.toggleOnlineMode(val),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),

          if (settings.isOnlineMode) ...[
            const SizedBox(height: 8),
            Text(
                'Améliore la fiabilité des prix.',
                style: AppTypography.caption.copyWith(color: AppColors.textTertiary)
            ),
            const SizedBox(height: 12),
            if (settings.hasFmpApiKey)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text('Clé active', style: AppTypography.caption.copyWith(color: AppColors.success)),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fmpKeyController,
                    obscureText: _obscureFmpKey,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      labelText: 'Clé API FMP',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureFmpKey ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _obscureFmpKey = !_obscureFmpKey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'OK',
                  onPressed: () => _saveFmpKey(settings),
                  isFullWidth: false,
                  type: AppButtonType.secondary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}