// lib/features/01_launch/ui/splash_screen.dart

import 'dart:ui'; // Nécessaire pour ImageFilter
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

// Design System
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
// ignore: unused_import
import 'package:portefeuille/core/ui/theme/app_dimens.dart';

// Logic
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/services/route_manager.dart';

// ignore_for_file: use_build_context_synchronously

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();

    // 1. Animation lente et infinie pour les orbes d'arrière-plan
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    // 2. Animation d'entrée du contenu (Fade in + Slide up)
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Démarrage après un petit délai pour laisser l'UI se monter
    Future.delayed(const Duration(milliseconds: 100), () {
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final settings = Provider.of<SettingsProvider>(context);
    final Color primaryColor = settings.appColor; // La couleur choisie par l'utilisateur

    // Navigation Logic
    final portfolioProvider = context.watch<PortfolioProvider>();
    if (!portfolioProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Petit délai artificiel pour laisser l'utilisateur apprécier l'animation (optionnel)
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            final bool hasPortfolios = portfolioProvider.portfolios.isNotEmpty;
            final String nextRoute = hasPortfolios ? RouteManager.dashboard : RouteManager.launch;
            Navigator.of(context).pushReplacementNamed(nextRoute);
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background, // Fond sombre de base
      body: Stack(
        children: [
          // --- COUCHE 1 : Background Ambient (Orbes colorées) ---
          _buildAmbientBackground(size, primaryColor),

          // --- COUCHE 2 : Effet "Grain" ou Overlay sombre pour le contraste ---
          Container(
            color: Colors.black.withValues(alpha: 0.3), // Assombrit légèrement pour faire ressortir le verre
          ),

          // --- COUCHE 3 : Contenu Glassmorphism ---
          Center(
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                final double opacity = CurvedAnimation(
                  parent: _entranceController,
                  curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                ).value;

                final double slide = CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.easeOutCubic,
                ).value;

                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - slide)), // Léger mouvement vers le haut
                    child: child,
                  ),
                );
              },
              child: _buildGlassCard(primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBackground(Size size, Color primaryColor) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final progress = _backgroundController.value;

        return Stack(
          children: [
            // Orbe Haut-Gauche (Couleur Primaire)
            Positioned(
              top: -100 + (progress * 50),
              left: -100 + (progress * 30),
              child: _buildOrb(primaryColor, size.width * 0.8),
            ),
            // Orbe Bas-Droite (Couleur Secondaire/Complémentaire)
            Positioned(
              bottom: -100 + (progress * 60),
              right: -100 + (progress * 40),
              child: _buildOrb(
                HSLColor.fromColor(primaryColor).withHue((HSLColor.fromColor(primaryColor).hue + 30) % 360).toColor(),
                size.width * 0.9,
              ),
            ),
            // Orbe Centre (Plus subtile)
            Positioned(
              top: size.height * 0.3 + (math.sin(progress * math.pi) * 50),
              left: size.width * 0.2,
              child: _buildOrb(Colors.white, size.width * 0.4, opacity: 0.05),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrb(Color color, double diameter, {double opacity = 0.4}) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  Widget _buildGlassCard(Color primaryColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          // --- MODIFICATION ICI ---
          // On supprime 'width: 320' et on utilise des contraintes
          constraints: BoxConstraints(
            minWidth: 300, // Largeur minimale pour l'élégance
            maxWidth: MediaQuery.of(context).size.width * 0.9, // Max 90% de l'écran
          ),
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
          // -------------------------
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(primaryColor),
              const SizedBox(height: 40),

              // J'ajoute un FittedBox ici par sécurité pour les petits écrans
              // afin que le texte réduise sa taille plutôt que de passer à la ligne
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Shimmer.fromColors(
                  baseColor: Colors.white,
                  highlightColor: Colors.white.withValues(alpha: 0.5),
                  period: const Duration(milliseconds: 2500),
                  child: Text(
                    'PORTEFEUILLE',
                    style: AppTypography.h2.copyWith(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Important pour centrer le Row
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible( // Permet au texte de ne pas casser la layout si très long
                    child: Text(
                      'Initialisation sécurisée',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: const Center(
        child: Text(
          'P',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cinzel', // Si dispo, ou garde défaut
          ),
        ),
      ),
    );
  }
}