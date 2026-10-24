import 'package:flutter_test/flutter_test.dart';
import 'package:moon_safe/main.dart';

void main() {
  testWidgets('MoonSafe app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MoonSafeApp());
    expect(find.text('MoonSafe'), findsOneWidget);
  });
}
