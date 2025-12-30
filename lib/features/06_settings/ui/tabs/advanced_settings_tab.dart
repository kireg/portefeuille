import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/widgets/fade_in_slide.dart';
import '../widgets/sync_logs_card.dart';
import '../widgets/backup_card.dart';
import '../widgets/debug_card.dart';
import '../widgets/danger_zone_card.dart';

class AdvancedSettingsTab extends StatelessWidget {
  const AdvancedSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      children: const [
        FadeInSlide(delay: 0.1, child: SyncLogsCard()),
        SizedBox(height: AppDimens.paddingM),
        FadeInSlide(delay: 0.15, child: BackupCard()),
        SizedBox(height: AppDimens.paddingM),
        FadeInSlide(delay: 0.2, child: DebugCard()),
        SizedBox(height: AppDimens.paddingM),
        FadeInSlide(delay: 0.25, child: DangerZoneCard()),
      ],
    );
  }
}
