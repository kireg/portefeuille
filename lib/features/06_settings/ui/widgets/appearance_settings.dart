// lib/features/06_settings/ui/widgets/appearance_settings.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';

// Liste des couleurs prédéfinies
final List<Color> _colorOptions = [
  const Color(0xFF00bcd4), // Cyan (Défaut)
  Colors.blue,
  Colors.green,
  const Color(0xFFab47bc), // Violet (Secondaire)
  Colors.orange,
  Colors.redAccent,
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
        const SizedBox(height: 8),
        Text(
          'Cette couleur sera utilisée pour les boutons, les icônes et les éléments actifs de l\'interface.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
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
              color: widget.isSelected ? Colors.white : Colors.transparent,
              width: widget.isSelected ? 4 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: widget.isSelected || _isHovered ? 12 : 4,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: widget.isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 24)
              : null,
        ),
      ),
    );
  }
}