import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/app.dart';

void main() {
  testWidgets('shows the Luna application title', (WidgetTester tester) async {
    await tester.pumpWidget(const LunaApp());

    expect(find.text('Luna'), findsOneWidget);
  });

  testWidgets('uses Vietnamese as the default locale',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LunaApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.locale, const Locale('vi'));
  });
}
