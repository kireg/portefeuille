import 'package:flutter/material.dart';
import 'package:portefeuille/core/Design_Center/theme/app_dimens.dart';
import 'package:portefeuille/core/Design_Center/widgets/fade_in_slide.dart';
import '../widgets/about_card.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      children: const [
        FadeInSlide(delay: 0.1, child: AboutCard()),
      ],
    );
  }
}
