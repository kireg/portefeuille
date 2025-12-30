import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_animations.dart';

class AppAnimatedBackground extends StatefulWidget {
  final Widget child;
  const AppAnimatedBackground({super.key, required this.child});

  @override
  State<AppAnimatedBackground> createState() => _AppAnimatedBackgroundState();
}

class _AppAnimatedBackgroundState extends State<AppAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    // Animation très lente (10 secondes) pour un effet "respiration"
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slowest,
    )..repeat(reverse: true);

    // Mouvements sinusoïdaux décalés
    _animation1 = Tween<double>(begin: -0.5, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _animation2 = Tween<double>(begin: 0.5, end: -0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _animation3 = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On récupère les couleurs du thème actif
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final surface = AppColors.background;

    return Stack(
      children: [
        // 1. Fond de base solide
        Container(color: surface),

        // 2. Orbes de lumière animés
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Orbe 1 : En haut à gauche (Couleur Primaire)
                Positioned(
                  top: -100 + (_animation1.value * 50),
                  left: -100 + (_animation2.value * 30),
                  child: _buildGlowOrb(primary, 400),
                ),

                // Orbe 2 : En bas à droite (Couleur Secondaire)
                Positioned(
                  bottom: -100 + (_animation2.value * 50),
                  right: -100 + (_animation1.value * 30),
                  child: _buildGlowOrb(secondary, 350),
                ),

                // Orbe 3 : Au centre (Lumière diffuse)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.3 + (_animation2.value * 100),
                  left: -200,
                  child: Opacity(
                    opacity: 0.4, // Plus subtil
                    child: _buildGlowOrb(Colors.cyanAccent, 500 * _animation3.value),
                  ),
                ),
              ],
            );
          },
        ),

        // 3. Flou Massif (Mesh Effect) - REMPLACÉ PAR DES GRADIENTS
        // L'ancien BackdropFilter était trop coûteux en performances.
        // Les orbes utilisent maintenant des RadialGradients pour l'effet de flou.
        
        // 4. Filtre de bruit (Optionnel, pour la texture "Papier")
        // On ajoute un voile très léger pour unifier le tout
        Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.7), // Réduit l'intensité des couleurs
          ),
        ),

        // 5. Le contenu de l'écran par dessus
        widget.child,
      ],
    );
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.5),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.7], // Fade out before the edge
        ),
      ),
    );
  }
}