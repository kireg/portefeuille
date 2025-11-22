import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';

class CrowdfundingMapWidget extends StatelessWidget {
  final List<Asset> assets;

  const CrowdfundingMapWidget({
    super.key,
    required this.assets,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrer les actifs qui ont des coordonnées valides
    final validAssets = assets.where((asset) {
      return asset.latitude != null && asset.longitude != null;
    }).toList();

    // On affiche la carte même vide pour montrer la fonctionnalité
    // if (validAssets.isEmpty) {
    //   return const SizedBox.shrink(); 
    // }

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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(46.603354, 1.888334), // Centre de la France
                initialZoom: 5.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAssetDetails(BuildContext context, Asset asset) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.projectName ?? asset.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Localisation: ${asset.location ?? "Inconnue"}'),
              Text('Rendement: ${asset.estimatedAnnualYield.toStringAsFixed(2)}%'),
              if (asset.riskRating != null)
                Text('Risque: ${asset.riskRating}'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
}
