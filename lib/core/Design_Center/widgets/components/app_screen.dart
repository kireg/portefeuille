import 'package:flutter/material.dart';
// import '../../theme/app_colors.dart'; // Plus besoin si on utilise le fond animé
import 'app_animated_background.dart'; // Import du nouveau widget

class AppScreen extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool withSafeArea;

  const AppScreen({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.withSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Contenu principal (Scaffold transparent)
    Widget content = Scaffold(
      backgroundColor: Colors.transparent, // Important : transparent pour voir le fond animé
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      extendBody: true,
    );

    // 2. Gestion SafeArea
    if (withSafeArea) {
      content = SafeArea(
        bottom: false,
        child: content,
      );
    }

    // 3. Wrapper avec le fond animé "Aurora"
    return AppAnimatedBackground(
      child: content,
    );
  }
}