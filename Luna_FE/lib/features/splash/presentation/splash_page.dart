import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Semantics(
      label: 'Luna đang khởi động',
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nightlight_round, size: 64, color: AppColor.menstrual),
            SizedBox(height: 16),
            Text('Luna'),
          ],
        ),
      ),
    ),
  );
}
