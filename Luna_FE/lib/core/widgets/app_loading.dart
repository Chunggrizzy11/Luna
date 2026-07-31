import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({this.label = 'Đang tải', super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    liveRegion: true,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.sm),
          Text(label),
        ],
      ),
    ),
  );
}
