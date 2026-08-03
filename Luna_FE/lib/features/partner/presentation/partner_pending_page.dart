import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class PartnerPendingPage extends StatelessWidget {
  const PartnerPendingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Luna đồng hành')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_outline, size: 56),
            SizedBox(height: AppSpacing.md),
            Text(
              'Trải nghiệm dành cho người đồng hành đang được chuẩn bị.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Dữ liệu sức khỏe riêng tư của chủ tài khoản không được hiển thị tại đây.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
