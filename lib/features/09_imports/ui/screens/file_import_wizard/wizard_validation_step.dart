import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/Design_Center/theme/app_colors.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/theme/app_spacing.dart';
import 'package:portefeuille/core/Design_Center/theme/app_typography.dart';
import 'package:portefeuille/core/Design_Center/theme/app_opacities.dart';
import 'package:portefeuille/core/Design_Center/theme/app_component_sizes.dart';
import 'package:portefeuille/core/Design_Center/widgets/inputs/app_dropdown.dart';
import 'package:portefeuille/core/Design_Center/widgets/primitives/app_button.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/i18n/strings.dart';
import 'package:portefeuille/features/09_imports/ui/screens/file_import_wizard/wizard_candidate_card.dart';
import 'package:portefeuille/features/09_imports/ui/screens/file_import_wizard/wizard_state.dart';

/// Étape 2 du wizard : validation et sélection des transactions.
/// 
/// Affiche l'état du parsing, les erreurs éventuelles,
/// les avertissements et la liste des candidats.
class WizardValidationStep extends StatelessWidget {
  final WizardState state;
  final VoidCallback onRetryParse;
  final VoidCallback onSaveWithWarning;
  final ValueChanged<String?> onAccountChanged;
  final void Function(int index, ImportCandidate updated) onCandidateUpdated;
  final void Function(int index) onCandidateDeleted;
  final ValueChanged<bool> onWarningConfirmed;

  const WizardValidationStep({
    super.key,
    required this.state,
    required this.onRetryParse,
    required this.onSaveWithWarning,
    required this.onAccountChanged,
    required this.onCandidateUpdated,
    required this.onCandidateDeleted,
    required this.onWarningConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isParsing) {
      return _buildLoadingState();
    }

    if (state.parsingError != null) {
      return _buildErrorState();
    }

    if (state.parserWarning != null && state.candidates == null) {
      return _buildWarningOnlyState();
    }

    if (state.candidates == null || state.candidates!.isEmpty) {
      return const Center(child: Text(StringsImport.noneFound));
    }

    return _buildCandidatesList(context);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          AppSpacing.gapM,
          const Text("Analyse du fichier en cours..."),
          AppSpacing.gapS,
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: state.parsingProgress,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          AppSpacing.gapXs,
          Text("${(state.parsingProgress * 100).toInt()}%"),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: AppComponentSizes.iconXLarge),
          AppSpacing.gapM,
          Text(
            "Erreur lors de l'analyse",
            style: AppTypography.h3.copyWith(color: AppColors.error),
          ),
          AppSpacing.gapS,
          Text(state.parsingError!, textAlign: TextAlign.center),
          AppSpacing.gapL,
          AppButton(
            label: "Réessayer",
            onPressed: onRetryParse,
            type: AppButtonType.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningOnlyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: AppComponentSizes.iconXLarge,
          ),
          AppSpacing.gapM,
          Text(
            StringsImport.warningTitle,
            style: AppTypography.h3.copyWith(color: AppColors.warning),
          ),
          AppSpacing.gapS,
          Text(state.parserWarning!, textAlign: TextAlign.center),
          AppSpacing.gapL,
          AppButton(
            label: StringsImport.continueDespiteWarning,
            onPressed: onSaveWithWarning,
            type: AppButtonType.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatesList(BuildContext context) {
    final portfolioProvider = context.watch<PortfolioProvider>();
    final activePortfolio = portfolioProvider.activePortfolio;
    final accountItems = _buildAccountDropdownItems(activePortfolio);
    final modifiedCount = state.candidates!.where((c) => c.isModified).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.parserWarning != null) _buildWarningBanner(),
        Text(StringsImport.validationTitle, style: AppTypography.h2),
        AppSpacing.gapS,
        Text(
          "${state.candidates!.length} transactions retenues "
          "($modifiedCount modifiées)",
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        AppSpacing.gapM,
        if (_hasValidationWarnings()) _buildValidationWarnings(),
        AppDropdown<String>(
          label: StringsImport.destinationAccount,
          value: state.selectedAccountId,
          items: accountItems,
          onChanged: onAccountChanged,
        ),
        AppSpacing.gapM,
        Expanded(child: _buildTransactionsList()),
      ],
    );
  }

  bool _hasValidationWarnings() {
    return state.duplicateTransactions.isNotEmpty ||
        state.invalidIsinTransactions.isNotEmpty;
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: AppOpacities.lightOverlay),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          AppSpacing.gapH12,
          Expanded(
            child: Text(
              state.parserWarning!,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationWarnings() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: AppOpacities.lightOverlay),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              AppSpacing.gapHorizontalSmall,
              Text(
                StringsImport.attentionRequired,
                style: AppTypography.h3.copyWith(color: AppColors.warning),
              ),
            ],
          ),
          AppSpacing.gapS,
          if (state.duplicateTransactions.isNotEmpty)
            Text(
              "• ${state.duplicateTransactions.length} doublons potentiels "
              "détectés (même date, quantité, montant).",
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
          if (state.invalidIsinTransactions.isNotEmpty)
            Text(
              "• ${state.invalidIsinTransactions.length} codes ISIN "
              "semblent invalides.",
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
          AppSpacing.gap12,
          Row(
            children: [
              Checkbox(
                value: state.hasConfirmedWarnings,
                activeColor: AppColors.warning,
                onChanged: (val) => onWarningConfirmed(val ?? false),
              ),
              Expanded(
                child: Text(
                  "Je confirme vouloir importer ces transactions "
                  "malgré les avertissements.",
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final candidates = state.candidates!;
    final newOnes = candidates.where((c) => !c.isModified).toList();
    final modified = candidates.where((c) => c.isModified).toList();

    return ListView(
      children: [
        if (newOnes.isNotEmpty) ...[
          Text(
            "${StringsImport.newLabel} (${newOnes.length})",
            style: AppTypography.h3,
          ),
          AppSpacing.gapS,
          ...newOnes.map((c) => _buildCard(candidates.indexOf(c), c)),
          AppSpacing.gapM,
        ],
        if (modified.isNotEmpty) ...[
          Text(
            "${StringsImport.modifiedLabel} (${modified.length})",
            style: AppTypography.h3,
          ),
          AppSpacing.gapS,
          ...modified.map((c) => _buildCard(candidates.indexOf(c), c)),
        ],
      ],
    );
  }

  Widget _buildCard(int index, ImportCandidate candidate) {
    return WizardCandidateCard(
      candidate: candidate,
      onSelectionChanged: (selected) {
        onCandidateUpdated(index, candidate.copyWith(selected: selected));
      },
      onEdit: (updated) {
        onCandidateUpdated(index, candidate.copyWith(parsed: updated));
      },
      onDelete: () => onCandidateDeleted(index),
    );
  }

  List<DropdownMenuItem<String>> _buildAccountDropdownItems(dynamic portfolio) {
    final items = <DropdownMenuItem<String>>[];
    if (portfolio == null) return items;

    for (final institution in portfolio.institutions) {
      for (final account in institution.accounts) {
        items.add(
          DropdownMenuItem(
            value: account.id,
            child: Text("${institution.name} - ${account.name}"),
          ),
        );
      }
    }
    return items;
  }
}
