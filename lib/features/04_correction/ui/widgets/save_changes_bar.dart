// lib/features/04_correction/ui/widgets/save_changes_bar.dart

import 'package:flutter/material.dart';

/// Affiche la barre de sauvegarde/annulation en bas
class SaveChangesBar extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const SaveChangesBar({super.key, required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        bottom: true,
        child: Material(
          elevation: 8,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.12),
                ),
              ),
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modifications non sauvegardées',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pensez à sauvegarder vos changements',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler'),
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                    onPressed: onSave,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}