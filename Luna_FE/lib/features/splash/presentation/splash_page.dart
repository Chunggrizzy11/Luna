import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColor.pageGradient(Theme.of(context).brightness),
        ),
        child: Semantics(
          label: 'Luna đang khởi động',
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.brand.withValues(alpha: 0.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.brand.withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            )
                          ]
                        ),
                        child: const Icon(
                          Icons.nightlight_round, 
                          size: 72, 
                          color: AppColor.accentIndigo
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Luna',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.brandStrong(isDark ? Brightness.dark : Brightness.light),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
