import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/widgets/fade_in_slide.dart';
import '../widgets/appearance_card.dart';
import '../widgets/general_settings_card.dart';
import '../widgets/portfolio_card.dart';
import '../widgets/online_mode_card.dart';

class GeneralSettingsTab extends StatelessWidget {
  const GeneralSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      children: const [
        FadeInSlide(delay: 0.1, child: AppearanceCard()),
        SizedBox(height: AppDimens.paddingM),
        FadeInSlide(delay: 0.15, child: GeneralSettingsCard()),
        SizedBox(height: AppDimens.paddingM),
        FadeInSlide(delay: 0.2, child: PortfolioCard()),
        SizedBox(height: AppDimens.paddingM),
        FadeInSlide(delay: 0.25, child: OnlineModeCard()),
      ],
    );
  }
}
