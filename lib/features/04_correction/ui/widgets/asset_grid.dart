// lib/features/04_correction/ui/widgets/asset_grid.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'asset_editor_tile.dart';

/// Affiche la grille éditable pour les Actifs (Assets)
class AssetGrid extends StatelessWidget {
  final List<Asset> assets;
  final void Function(int) onDeleteAsset;
  final VoidCallback onDataChanged;

  const AssetGrid({
    super.key,
    required this.assets,
    required this.onDeleteAsset,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (assets.isEmpty) {
      return const SizedBox(height: 8); // Juste un petit espace
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const targetWidth = 380.0;
        const spacing = 12.0;
        int columns = (constraints.maxWidth / (targetWidth + spacing)).floor();
        columns = columns.clamp(1, 3);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 1.8,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: 180,
          ),
          itemCount: assets.length,
          itemBuilder: (context, assetIndex) {
            final asset = assets[assetIndex];
            return Stack(
              children: [
                AssetEditorTile(
                  key: ValueKey(asset.id), // Utiliser l'ID unique de l'asset
                  asset: asset,
                  onChanged: onDataChanged,
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: 'Supprimer l\'actif',
                    onPressed: () => onDeleteAsset(assetIndex),
                    style: IconButton.styleFrom(
                      backgroundColor:
                      theme.scaffoldBackgroundColor.withOpacity(0.8),
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(24, 24),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}