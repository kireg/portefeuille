import 'package:flutter/material.dart';
import 'package:portefeuille/features/07_management/services/excel/parsed_crowdfunding_project.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/repayment_type.dart'; // Added import
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';

class CrowdfundingProjectList extends StatelessWidget {
  final List<ParsedCrowdfundingProject> projects;
  final Account? selectedAccount;
  final Function(int) onEdit;
  final Function(int) onRemove;
  final String? loadingStatus;

  const CrowdfundingProjectList({
    super.key,
    required this.projects,
    required this.selectedAccount,
    required this.onEdit,
    required this.onRemove,
    this.loadingStatus,
  });

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    if (loadingStatus != null) {
      return Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loadingStatus!, style: AppTypography.body),
          ],
        ),
      );
    }

    if (projects.isEmpty) return const SizedBox.shrink();

    return Column(
      children: projects.asMap().entries.map((entry) {
        final index = entry.key;
        final project = entry.value;
        final isDuplicate = selectedAccount != null && selectedAccount!.transactions.any((t) =>
            t.assetName == project.projectName &&
            (t.amount - project.investedAmount).abs() < 0.01 &&
            (project.investmentDate == null || _isSameDay(t.date, project.investmentDate!)));

        return FadeInSlide(
          delay: 0.2 + (index * 0.05),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
            child: Dismissible(
              key: ValueKey(project.projectName),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => onRemove(index),
              background: Container(
                color: AppColors.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: AppCard(
                backgroundColor: isDuplicate ? AppColors.warning.withOpacity(0.1) : null,
                onTap: () => onEdit(index),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(project.projectName, style: AppTypography.bodyBold)),
                      if (isDuplicate)
                        const Tooltip(
                          message: "Ce projet existe déjà et sera ignoré",
                          child: Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    "${project.investedAmount} € • ${project.yieldPercent}% • ${project.durationMonths} mois",
                    style: AppTypography.caption,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        project.repaymentType.displayName,
                        style: AppTypography.caption.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
