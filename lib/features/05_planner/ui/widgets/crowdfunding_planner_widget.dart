import 'package:flutter/gestures.dart'; // Pour ScrollConfiguration
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_opacities.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/00_app/services/crowdfunding_service.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/ui/theme/app_spacing.dart';

class CrowdfundingPlannerWidget extends StatefulWidget {
  final List<Asset> assets;
  final List<Transaction> transactions;

  const CrowdfundingPlannerWidget({
    super.key,
    required this.assets,
    required this.transactions,
  });

  @override
  State<CrowdfundingPlannerWidget> createState() => _CrowdfundingPlannerWidgetState();
}

class _CrowdfundingPlannerWidgetState extends State<CrowdfundingPlannerWidget> {
  final Set<String> _selectedProjectTickers = {};

  List<Asset> get _crowdfundingAssets {
    return widget.assets
        .where((a) => a.type == AssetType.RealEstateCrowdfunding)
        .toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Filtrer par projet"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _crowdfundingAssets.length,
                  itemBuilder: (context, index) {
                    final asset = _crowdfundingAssets[index];
                    final isSelected = _selectedProjectTickers.contains(asset.ticker);
                    return CheckboxListTile(
                      title: Text(asset.name),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedProjectTickers.add(asset.ticker);
                          } else {
                            _selectedProjectTickers.remove(asset.ticker);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedProjectTickers.clear();
                    });
                  },
                  child: const Text("Tout effacer"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    this.setState(() {}); // Rebuild parent
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Utilisation du service (idéalement injecté ou via un provider dédié)
    final service = CrowdfundingService();
    
    // Utilisation de la nouvelle méthode generateFutureEvents qui est plus précise
    final allEvents = service.generateFutureEvents(
      assets: _crowdfundingAssets,
      transactions: widget.transactions,
      projectionMonths: 24, // On regarde les 2 prochaines années pour le planner
    );

    final futureEvents = allEvents.where((e) {
      if (_selectedProjectTickers.isEmpty) return true;
      return _selectedProjectTickers.contains(e.assetId);
    }).toList();

    if (allEvents.isEmpty) {
      return const SizedBox.shrink(); // Rien à afficher si pas de crowdfunding
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Prochains Paiements",
                style: AppTypography.h3,
              ),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _selectedProjectTickers.isNotEmpty ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        
        if (futureEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppDimens.paddingM),
            child: Center(child: Text("Aucun paiement pour les projets sélectionnés.")),
          )
        else
          SizedBox(
            height: 160,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                itemCount: futureEvents.length,
                itemBuilder: (context, index) {
                  final event = futureEvents[index];
                  final isCapital = event.type == TransactionType.CapitalRepayment;
                  
                  // Récupérer le nom de l'actif
                  final asset = widget.assets.where((a) => a.id == event.assetId || a.ticker == event.assetId).firstOrNull;
                  final assetName = asset?.name ?? event.assetId ?? "Inconnu";

                  return Container(
                    width: 140,
                    margin: EdgeInsets.only(
                      right: index == futureEvents.length - 1 ? 0 : AppDimens.paddingS
                    ),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      backgroundColor: isCapital ? AppColors.primary.withValues(alpha: AppOpacities.lightOverlay) : AppColors.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy', 'fr_FR').format(event.date),
                            style: AppTypography.caption,
                          ),
                          AppSpacing.gapXs,
                          Text(
                            "${event.amount.toStringAsFixed(2)} €",
                            style: AppTypography.h3.copyWith(
                              color: isCapital ? AppColors.primary : AppColors.success,
                              fontSize: 18,
                            ),
                          ),
                          AppSpacing.gapXs,
                          Text(
                            assetName,
                            style: AppTypography.body.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isCapital ? "Remboursement" : "Intérêts",
                            style: AppTypography.caption.copyWith(
                              color: isCapital ? AppColors.primary : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
