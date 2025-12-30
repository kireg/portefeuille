import 'package:flutter/material.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import '../../theme/app_animations.dart';

class AppAnimatedValue extends StatefulWidget {
  final double value;
  final String currency;
  final TextStyle? style;
  final Duration duration;

  const AppAnimatedValue({
    super.key,
    required this.value,
    required this.currency,
    this.style,
    this.duration = AppAnimations.slowest,
  });

  @override
  State<AppAnimatedValue> createState() => _AppAnimatedValueState();
}

class _AppAnimatedValueState extends State<AppAnimatedValue> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    // MODIFICATION : On ne force plus l'animation depuis 0 à l'initialisation
    // pour éviter l'effet de "reset" lors des rebuilds (ex: toggle privacy).
    // L'animation se fera uniquement si la valeur change via didUpdateWidget.
    _animation = Tween<double>(begin: widget.value, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );
    _controller.forward();
    _oldValue = widget.value;
  }

  @override
  void didUpdateWidget(AppAnimatedValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _controller.reset();
      _animation = Tween<double>(begin: _oldValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
      );
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          CurrencyFormatter.format(_animation.value, widget.currency),
          style: widget.style,
        );
      },
    );
  }
}