import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk/app.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const KioskApp());
    expect(find.text('КДЦ'), findsOneWidget);
    expect(find.text('Тимоново'), findsOneWidget);
  });
}
