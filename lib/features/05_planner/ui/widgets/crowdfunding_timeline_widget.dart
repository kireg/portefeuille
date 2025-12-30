import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/features/07_management/ui/screens/edit_transaction_screen.dart';

class CrowdfundingTimelineWidget extends StatefulWidget {
  final List<Asset> assets;

  const CrowdfundingTimelineWidget({
    super.key,
    required this.assets,
  });

  @override
  State<CrowdfundingTimelineWidget> createState() =>
      _CrowdfundingTimelineWidgetState();
}

class _CrowdfundingTimelineWidgetState
    extends State<CrowdfundingTimelineWidget> {
  final Set<String> _selectedProjectIds = {};

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
                  itemCount: widget.assets.length,
                  itemBuilder: (context, index) {
                    final asset = widget.assets[index];
                    final isSelected = _selectedProjectIds.contains(asset.id);
                    return CheckboxListTile(
                      title: Text(asset.name),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedProjectIds.add(asset.id);
                          } else {
                            _selectedProjectIds.remove(asset.id);
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
                      _selectedProjectIds.clear();
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
    if (widget.assets.isEmpty) return const SizedBox.shrink();

    // Filtrer
    final filteredAssets = widget.assets.where((a) {
      if (_selectedProjectIds.isEmpty) return true;
      return _selectedProjectIds.contains(a.id);
    }).toList();

    if (filteredAssets.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Calendrier des Projets",
                  style: AppTypography.h3,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: AppColors.primary),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppDimens.paddingM),
            child: Center(child: Text("Aucun projet sélectionné.")),
          ),
        ],
      );
    }

    // Trier par date de fin estimée
    final sortedAssets = List<Asset>.from(filteredAssets);
    sortedAssets.sort((a, b) {
      final endA = _getEndDate(a);
      final endB = _getEndDate(b);
      return endA.compareTo(endB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Calendrier des Projets",
                style: AppTypography.h3,
              ),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _selectedProjectIds.isNotEmpty
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        SizedBox(
          height: 400, // Hauteur fixe pour le scroll
          child: ListView.builder(
            shrinkWrap: true,
            // physics: const NeverScrollableScrollPhysics(), // REMOVED to allow scrolling
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
            itemCount: sortedAssets.length,
            itemBuilder: (context, index) {
              final asset = sortedAssets[index];
              final endDate = _getEndDate(asset);
              final isLast = index == sortedAssets.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colonne Date
                    SizedBox(
                      width: 50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('MMM', 'fr_FR')
                                .format(endDate)
                                .toUpperCase(),
                            style: AppTypography.bodyBold
                                .copyWith(color: AppColors.primary),
                          ),
                          Text(
                            DateFormat('yyyy', 'fr_FR').format(endDate),
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.paddingS),
                    // Ligne Timeline
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.background, width: 2),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isLast
                                ? Colors.transparent
                                : AppColors.surfaceLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppDimens.paddingM),
                    // Carte Projet
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppDimens.paddingM),
                        child: _CrowdfundingProjectCard(asset: asset),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  DateTime _getStartDate(Asset asset) {
    if (asset.transactions.isEmpty) return DateTime.now();
    final buyTransactions =
        asset.transactions.where((t) => t.type == TransactionType.Buy).toList();
    if (buyTransactions.isEmpty) return DateTime.now();
    buyTransactions.sort((a, b) => a.date.compareTo(b.date));
    return buyTransactions.first.date;
  }

  DateTime _getEndDate(Asset asset) {
    final start = _getStartDate(asset);
    // On base l'estimation sur la durée maximale si disponible
    final duration = asset.maxDuration ?? asset.targetDuration ?? 0;
    return start.add(Duration(days: duration * 30));
  }
}

class _CrowdfundingProjectCard extends StatefulWidget {
  final Asset asset;

  const _CrowdfundingProjectCard({required this.asset});

  @override
  State<_CrowdfundingProjectCard> createState() =>
      _CrowdfundingProjectCardState();
}

class _CrowdfundingProjectCardState extends State<_CrowdfundingProjectCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    final startDate = _getStartDate(asset);
    final endDate = _getEndDate(asset);
    final now = DateTime.now();
    final totalDuration = endDate.difference(startDate).inDays;
    final elapsed = now.difference(startDate).inDays;
    final progress =
        (totalDuration > 0) ? (elapsed / totalDuration).clamp(0.0, 1.0) : 0.0;

    // Calculs financiers
    double invested = 0.0;
    double interests = 0.0;
    double repaidCapital = 0.0;

    for (var t in asset.transactions) {
      if (t.type == TransactionType.Buy) {
        invested += t.amount.abs();
      } else if (t.type == TransactionType.Dividend ||
          t.type == TransactionType.Interest) {
        interests += t.amount;
      } else if (t.type == TransactionType.CapitalRepayment ||
          t.type == TransactionType.Sell) {
        repaidCapital += t.amount;
      }
    }

    final remainingCapital = invested - repaidCapital;
    final currency = asset.priceCurrency;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppDimens.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radius12),
          border: Border.all(
            color: _isExpanded
                ? AppColors.primary.withValues(alpha: AppOpacities.semiVisible)
                : Colors.white.withValues(alpha: AppOpacities.subtle),
          ),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: AppOpacities.lightOverlay),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    asset.name,
                    style: AppTypography.bodyBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton crayon pour éditer la transaction
                    if (_isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () => _editTransactionForAsset(context, asset),
                          child: Icon(
                            Icons.edit_outlined,
                            color: AppColors.primary,
                            size: AppComponentSizes.iconSmall,
                          ),
                        ),
                      ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: AppComponentSizes.iconMediumSmall,
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.gapS,
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusXs2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  endDate.isBefore(now) ? AppColors.error : AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
            AppSpacing.gapXs,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(progress * 100).toInt()}%",
                  style: AppTypography.caption,
                ),
                if (endDate.isBefore(now))
                  Text("Terminé",
                      style: AppTypography.caption
                          .copyWith(color: AppColors.success))
                else
                  Text("${endDate.difference(now).inDays} jours",
                      style: AppTypography.caption),
              ],
            ),

            // Details (Expandable)
            if (_isExpanded) ...[
              const SizedBox(height: AppDimens.paddingM),
              const Divider(height: 1, color: AppColors.surfaceLight),
              const SizedBox(height: AppDimens.paddingM),
              _buildDetailRow("Investi", invested, currency),
              AppSpacing.gapXs,
              _buildDetailRow("Intérêts perçus", interests, currency,
                  valueColor: AppColors.success),
              AppSpacing.gapXs,
              _buildDetailRow("Capital remboursé", repaidCapital, currency),
              AppSpacing.gapXs,
              _buildDetailRow("Restant dû", remainingCapital, currency,
                  isBold: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount, String currency,
      {Color? valueColor, bool isBold = false}) {
    final style = isBold ? AppTypography.bodyBold : AppTypography.caption;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        Text(
          "${NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)} $currency",
          style: style.copyWith(color: valueColor ?? AppColors.textPrimary),
        ),
      ],
    );
  }

  DateTime _getStartDate(Asset asset) {
    if (asset.transactions.isEmpty) return DateTime.now();
    final buyTransactions =
        asset.transactions.where((t) => t.type == TransactionType.Buy).toList();
    if (buyTransactions.isEmpty) return DateTime.now();
    buyTransactions.sort((a, b) => a.date.compareTo(b.date));
    return buyTransactions.first.date;
  }

  DateTime _getEndDate(Asset asset) {
    final start = _getStartDate(asset);
    // On base l'estimation sur la durée maximale si disponible
    final duration = asset.maxDuration ?? asset.targetDuration ?? 0;
    return start.add(Duration(days: duration * 30));
  }

  /// Ouvre l'écran de modification pour la première transaction d'achat du projet
  void _editTransactionForAsset(BuildContext context, Asset asset) {
    // Trouver la première transaction Buy pour éditer les données du projet
    try {
      final buyTransaction = asset.transactions
          .firstWhere((t) => t.type == TransactionType.Buy);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditTransactionScreen(
            existingTransaction: buyTransaction,
          ),
        ),
      );
    } catch (e) {
      // Pas de transaction Buy trouvée
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune transaction à modifier pour ce projet'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
