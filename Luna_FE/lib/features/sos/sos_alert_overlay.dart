import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'sos_provider.dart';

class SosAlertOverlay extends StatefulWidget {
  const SosAlertOverlay({super.key, required this.onAcknowledge});
  final VoidCallback onAcknowledge;

  static void show(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (context) => SosAlertOverlay(
        onAcknowledge: () {
          ref.read(sosProvider.notifier).acknowledge();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  State<SosAlertOverlay> createState() => _SosAlertOverlayState();
}

class _SosAlertOverlayState extends State<SosAlertOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _vibrateTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _vibrateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.withOpacity(0.9),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: const Icon(
                Icons.sos,
                size: 120,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'TÍN HIỆU KHẨN CẤP!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Người yêu đang cần bạn ngay lập tức.\nHãy liên hệ ngay!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 64),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              onPressed: widget.onAcknowledge,
              child: const Text('ĐÃ HIỂU 💙'),
            ),
          ],
        ),
      ),
    );
  }
}
