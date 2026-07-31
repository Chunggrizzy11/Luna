import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/widgets/app_button.dart';
import 'package:luna_fe/core/widgets/app_empty.dart';
import 'package:luna_fe/core/widgets/app_error.dart';
import 'package:luna_fe/core/widgets/app_loading.dart';

void main() {
  testWidgets('button announces loading and blocks duplicate presses', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AppButton(
          label: 'Tiếp tục',
          isLoading: true,
          onPressed: () => presses += 1,
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));

    expect(presses, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty, error and loading states expose readable labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            AppEmpty(message: 'Chưa có dữ liệu'),
            AppError(message: 'Không thể tải dữ liệu'),
            AppLoading(label: 'Đang tải'),
          ],
        ),
      ),
    );

    expect(find.text('Chưa có dữ liệu'), findsOneWidget);
    expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
    expect(find.text('Đang tải'), findsOneWidget);
  });
}
