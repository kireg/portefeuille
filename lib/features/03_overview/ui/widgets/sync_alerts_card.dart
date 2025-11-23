import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:portefeuille/core/data/models/sync_status.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_icon.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

import 'package:portefeuille/core/data/models/asset_metadata.dart';

class SyncAlertsCard extends StatelessWidget {
  const SyncAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<PortfolioProvider, ({Map<String, AssetMetadata> metadata, bool isProcessing})>(
      selector: (context, provider) => (
        metadata: provider.allMetadata,
        isProcessing: provider.isProcessingInBackground
      ),
      builder: (context, data, child) {
        final metadata = data.metadata;
        final isProcessing = data.isProcessing;

        // Filtrer les actifs
        final assetsWithErrors = metadata.entries
            .where((entry) => entry.value.syncStatus == SyncStatus.error)
            .toList();
        final neverSyncedCount = metadata.values
            .where((meta) => meta.syncStatus == SyncStatus.never)
            .length;
        final unsyncableCount = metadata.values
            .where((meta) => meta.syncStatus == SyncStatus.unsyncable)
            .length;

        if (assetsWithErrors.isEmpty && neverSyncedCount == 0 && unsyncableCount == 0) {
          return const SizedBox.shrink();
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  AppIcon(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Text('Alertes de synchronisation', style: AppTypography.h3),
                ],
              ),
              const SizedBox(height: AppDimens.paddingL),

              // 1. Jamais synchronisés
              if (neverSyncedCount > 0)
                _ExpandableAlertItem(
                  icon: Icons.info_outline,
                  color: AppColors.primary,
                  title: '$neverSyncedCount actif(s) jamais synchronisé(s)',
                  subtitle: 'Lancez une synchronisation pour récupérer les prix.',
                ),

              // 2. Non synchronisables
              if (unsyncableCount > 0)
                _ExpandableAlertItem(
                  icon: Icons.block,
                  color: AppColors.textTertiary,
                  title: '$unsyncableCount actif(s) non synchronisable(s)',
                  subtitle: 'Saisissez le prix manuellement (ex: Fonds euros).',
                ),

              // 3. Erreurs
              ...assetsWithErrors.map((entry) {
                return _ExpandableAlertItem(
                  icon: Icons.error_outline,
                  color: AppColors.error,
                  title: entry.key,
                  subtitle: entry.value.syncErrorMessage ?? 'Erreur inconnue',
                  metadata: entry.value,
                );
              }),

              const SizedBox(height: AppDimens.paddingL),

              // Bouton d'action
              AppButton(
                label: isProcessing ? 'TRAITEMENT...' : 'TOUT RESYNCHRONISER',
                isLoading: isProcessing,
                onPressed: isProcessing
                    ? null
                    : () => Provider.of<PortfolioProvider>(context, listen: false).synchroniserLesPrix(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpandableAlertItem extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final AssetMetadata? metadata;

  const _ExpandableAlertItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.metadata,
  });

  @override
  State<_ExpandableAlertItem> createState() => _ExpandableAlertItemState();
}

class _ExpandableAlertItemState extends State<_ExpandableAlertItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasDetails = widget.metadata != null &&
        (widget.metadata!.lastSyncAttempt != null ||
            (widget.metadata!.apiErrors?.isNotEmpty ?? false));

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        border: Border.all(color: widget.color.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasDetails
              ? () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }
              : null,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, color: widget.color, size: 20),
                    const SizedBox(width: AppDimens.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTypography.bodyBold.copyWith(color: widget.color),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    if (hasDetails)
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: widget.color,
                        size: 20,
                      ),
                  ],
                ),
                if (hasDetails)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: AppDimens.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: widget.color.withValues(alpha: 0.2)),
                          if (widget.metadata!.lastSyncAttempt != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "Dernier essai : ${DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.metadata!.lastSyncAttempt!)}",
                                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (widget.metadata!.apiErrors != null && widget.metadata!.apiErrors!.isNotEmpty)
                            ...widget.metadata!.apiErrors!.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      "${e.key} :",
                                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: AppTypography.caption.copyWith(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),
                    crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}