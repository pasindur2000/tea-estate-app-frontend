import 'package:flutter_test/flutter_test.dart';
import 'package:tea_state_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TeaStateApp());
    expect(find.byType(TeaStateApp), findsOneWidget);
  });
}
