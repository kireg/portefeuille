// lib/core/ui/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:math' as math;

// Imports du projet
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/01_launch/ui/launch_screen.dart';
import 'package:portefeuille/features/02_dashboard/ui/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _backgroundAnimationController; // Renommé pour plus de clarté
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation de pulsation pour les cercles
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation pour le fond (lignes)
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 15), // Durée ajustée pour l'animation des lignes
      vsync: this,
    )..repeat();

    // Animation de fade-in pour l'ensemble
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
    // Durée du splash
    await Future.delayed(const Duration(milliseconds: 3500));

    // Logique de navigation
    if (mounted) {
      final portfolioProvider =
      Provider.of<PortfolioProvider>(context, listen: false);

      final Widget nextScreen = portfolioProvider.portfolio != null
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
    _backgroundAnimationController.dispose(); // Dispose du nouveau contrôleur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final Color kColor = const Color(0xFF00bcd4); // primary
    final List<Color> gradientColors = [
      const Color(0xFF1a2943), // scaffoldBackgroundColor
      const Color(0xFF294166), // surface
    ];

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Fond animé avec lignes rotatives (NOUVEAU PAINTER)
            _buildAnimatedBackground(),

            // Contenu principal
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
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          // UTILISE LE NOUVEAU PAINTER
          painter: BackgroundLinesPainter(
            animationValue: _backgroundAnimationController.value,
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLogo(Color kColor) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Cercle extérieur pulsant
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
            // Cercle moyen
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
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: Colors.white.withOpacity(0.6),
      period: const Duration(milliseconds: 1500),
      child: const Text(
        'PORTEFEUILLE',
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

/// NOUVEAU Painter pour créer un effet de lignes en arrière-plan
class BackgroundLinesPainter extends CustomPainter {
  final double animationValue;

  BackgroundLinesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Pour des lignes plus douces

    // Nombre de lignes à dessiner
    final int numberOfLines = 8;
    // Angle de départ des lignes
    final double startAngle = -math.pi / 4; // Environ -45 degrés

    for (int i = 0; i < numberOfLines; i++) {
      // Calculer l'opacité et la largeur de la ligne en fonction de l'index
      final double opacity = 0.05 + (i * 0.02); // Les lignes deviennent légèrement plus visibles
      final double strokeWidth = 1.0 + (i * 0.5); // Les lignes deviennent plus épaisses
      linePaint.color = Colors.white.withOpacity(opacity);
      linePaint.strokeWidth = strokeWidth;

      // Calculer la position de la ligne
      // Utilisation de animationValue pour faire bouger les lignes
      final double offset = (animationValue * (size.width + size.height)) %
          (size.width + size.height);

      // Espacement entre les lignes
      final double lineSpacing = (size.width + size.height) / (numberOfLines + 2);

      // Calculer les points de départ et d'arrivée
      // Les lignes vont de haut-gauche à bas-droite
      final double linePosition = offset + (i * lineSpacing);

      // Les lignes traversent tout l'écran en diagonale
      final Offset p1 = Offset(linePosition - size.height, 0);
      final Offset p2 = Offset(linePosition, size.height);

      canvas.drawLine(p1, p2, linePaint);
    }

    // Ajouter quelques fines lignes verticales/horizontales pour un peu plus de détail
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