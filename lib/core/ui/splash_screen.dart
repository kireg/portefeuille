// lib/core/ui/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
// NOUVEL IMPORT
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/01_launch/ui/launch_screen.dart';
import 'package:portefeuille/features/02_dashboard/ui/dashboard_screen.dart';

// ... (State et initState/dispose/navigateToNextScreen inchangés [source 72-85]) ...
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      final portfolioProvider =
      Provider.of<PortfolioProvider>(context, listen: false);
      final bool hasPortfolios = portfolioProvider.portfolios.isNotEmpty;

      final Widget nextScreen = hasPortfolios
          ? const DashboardScreen()
          : const LaunchScreen();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final Color kColor = Provider.of<SettingsProvider>(context).appColor;

    // --- MODIFICATION ---
    // Les couleurs sont maintenant dynamiques et basées sur la couleur du provider
    final List<Color> gradientColors = [
      Color.lerp(kColor, Colors.black, 0.75)!, // Teinte la plus foncée
      Color.lerp(kColor, Colors.black, 0.6)! // Teinte un peu moins foncée
    ];
    // --- FIN MODIFICATION ---

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors, // Utilise les couleurs dynamiques
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedLogo(kColor),
                    const SizedBox(height: 48),
                    _buildShimmeredTitle(),
                    const SizedBox(height: 16),
                    _buildAnimatedSlogan(),
                    const SizedBox(height: 64),
                    _buildLoadingIndicator(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    // ... (inchangé [source 92-93]) ...
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: BackgroundLinesPainter(
            animationValue: _backgroundAnimationController.value,
          ),
        );
      },
    );
  }

  // MODIFIÉ : Accepte kColor en paramètre
  Widget _buildAnimatedLogo(Color kColor) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // ... (Cercles extérieurs inchangés [source 94-98]) ...
            Container(
              width: 180 * _pulseAnimation.value,
              height: 180 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 2,
                ),
              ),
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
            ),
            // Logo central
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: kColor,
                    letterSpacing: -2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmeredTitle() {
    // ... (inchangé [source 105]) ...
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: Colors.white.withOpacity(0.6),
      period: const Duration(milliseconds: 1500),
      child: const Text(
        'Portefeuille',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          letterSpacing: 6,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAnimatedSlogan() {
    // ... (inchangé [source 106-108]) ...
    return SizedBox(
      height: 40,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5,
        ),
        child: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Suivez vos investissements.',
              speed: const Duration(milliseconds: 80),
            ),
          ],
          repeatForever: false,
          isRepeatingAnimation: false,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    // ... (inchangé [source 109-112]) ...
    return Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Initialisation...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class BackgroundLinesPainter extends CustomPainter {
  // ... (Code du Painter inchangé [source 112-127]) ...
  final double animationValue;
  BackgroundLinesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final int numberOfLines = 8;

    for (int i = 0; i < numberOfLines; i++) {
      final double opacity = 0.05 + (i * 0.02);
      final double strokeWidth = 1.0 + (i * 0.5);
      linePaint.color = Colors.white.withOpacity(opacity);
      linePaint.strokeWidth = strokeWidth;
      final double offset = (animationValue * (size.width + size.height)) %
          (size.width + size.height);
      final double lineSpacing =
          (size.width + size.height) / (numberOfLines + 2);
      final double linePosition = offset + (i * lineSpacing);
      final Offset p1 = Offset(linePosition - size.height, 0);
      final Offset p2 = Offset(linePosition, size.height);

      canvas.drawLine(p1, p2, linePaint);
    }

    final fineLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 20; i++) {
      final double x = (animationValue * 50 + i * 80) % size.width;
      final double y = (animationValue * 70 + i * 60) % size.height;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), fineLinePaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fineLinePaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundLinesPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}