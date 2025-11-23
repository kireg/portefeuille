import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/core/ui/widgets/fade_in_slide.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';

class PdfAccountSelector extends StatelessWidget {
  final Account? selectedAccount;
  final ValueChanged<Account?> onChanged;

  const PdfAccountSelector({
    super.key,
    required this.selectedAccount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final accounts = provider.activePortfolio?.institutions
        .expand((inst) => inst.accounts)
        .toList() ?? [];

    return FadeInSlide(
      delay: 0.1,
      child: AppCard(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Compte de destination", style: AppTypography.h3),
            const SizedBox(height: AppDimens.paddingS),
            DropdownButtonFormField<Account>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              value: selectedAccount,
              isExpanded: true,
              items: () {
                // Group accounts by institution
                final groupedAccounts = <String, List<Account>>{};
                for (var acc in accounts) {
                  // Find institution name for this account
                  final inst = provider.activePortfolio?.institutions.firstWhere(
                    (i) => i.accounts.any((a) => a.id == acc.id),
                  );
                  final instName = inst?.name ?? "Autre";
                  groupedAccounts.putIfAbsent(instName, () => []).add(acc);
                }

                final items = <DropdownMenuItem<Account>>[];
                groupedAccounts.forEach((instName, accs) {
                  // Add Institution Header (disabled)
                  items.add(DropdownMenuItem<Account>(
                    enabled: false,
                    child: Text(
                      instName.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ));
                  // Add Accounts
                  for (var acc in accs) {
                    items.add(DropdownMenuItem<Account>(
                      value: acc,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(acc.name, style: AppTypography.body),
                      ),
                    ));
                  }
                });
                return items;
              }(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
