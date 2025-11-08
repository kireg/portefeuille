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
          'Apparence',
          style: theme.textTheme.titleMedium,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 8.0,
            runSpacing: 8.0,
            children: _colorOptions.map((color) {
              return _buildColorChip(
                  context, color, settingsProvider.appColor == color);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorChip(
      BuildContext context, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        Provider.of<SettingsProvider>(context, listen: false).setAppColor(color);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}