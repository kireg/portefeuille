import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';

class CrowdfundingMapWidget extends StatefulWidget {
  final List<Asset> assets;

  const CrowdfundingMapWidget({
    super.key,
    required this.assets,
  });

  @override
  State<CrowdfundingMapWidget> createState() => _CrowdfundingMapWidgetState();
}

class _CrowdfundingMapWidgetState extends State<CrowdfundingMapWidget> {
  final MapController _mapController = MapController();
  bool _isLocked = true;
  static const LatLng _franceCenter = LatLng(46.603354, 1.888334);
  static const double _defaultZoom = 5.5;

  @override
  Widget build(BuildContext context) {
    // Filtrer les actifs qui ont des coordonnées valides
    final validAssets = widget.assets.where((asset) {
      return asset.latitude != null && asset.longitude != null;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Carte des Projets",
                style: AppTypography.h3,
              ),
              if (validAssets.isEmpty)
                Text(
                  "(Aucun projet localisé)",
                  style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        Container(
          height: 400,
          margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _franceCenter,
                    initialZoom: _defaultZoom,
                    interactionOptions: InteractionOptions(
                      flags: _isLocked ? InteractiveFlag.none : InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    // Fond de carte "Dark Matter" pour le style Premium
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.myinvests.app',
                    ),
                    MarkerLayer(
                      markers: validAssets.map((asset) {
                        return Marker(
                          point: LatLng(asset.latitude!, asset.longitude!),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              _showAssetDetails(context, asset);
                            },
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.primary, // Utilisation de la couleur primaire (souvent dorée/premium)
                              size: 40,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 5)
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Bouton de verrouillage/déverrouillage
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.9),
                    onPressed: _toggleLock,
                    child: Icon(
                      _isLocked ? Icons.lock : Icons.lock_open,
                      color: _isLocked ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _mapController.move(_franceCenter, _defaultZoom);
      }
    });
  }

  void _showAssetDetails(BuildContext context, Asset asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.projectName ?? asset.name,
                style: AppTypography.h3,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.location_on_outlined, 'Localisation', asset.location ?? "Inconnue"),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.trending_up, 'Rendement', '${asset.estimatedAnnualYield.toStringAsFixed(2)}%'),
              if (asset.riskRating != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(Icons.shield_outlined, 'Risque', asset.riskRating!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: AppTypography.body)),
      ],
    );
  }
}
