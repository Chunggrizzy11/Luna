import 'package:flutter/material.dart';

class OnboardingIllustration extends StatefulWidget {
  const OnboardingIllustration({
    required this.icon,
    required this.color,
    required this.glowColor,
    this.size = 120,
    super.key,
  });

  final IconData icon;
  final Color color;
  final Color glowColor;
  final double size;

  @override
  State<OnboardingIllustration> createState() => _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.4 * _glowAnimation.value),
                  blurRadius: 40,
                  spreadRadius: 10 * _glowAnimation.value,
                ),
              ],
              border: Border.all(
                color: widget.color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              widget.icon,
              size: widget.size * 0.4,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}
