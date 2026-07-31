import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/app.dart';

void main() {
  testWidgets('shows the Luna application title', (WidgetTester tester) async {
    await tester.pumpWidget(const LunaApp());

    expect(find.text('Luna'), findsOneWidget);
  });
}
