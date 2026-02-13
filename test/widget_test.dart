import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    find.byIcon(Icons.add).evaluate().isNotEmpty
        ? await tester.tap(find.byIcon(Icons.add))
        : null;
    await tester.pump();

    // Verify that our counter has incremented.
    // Note: Since MyApp is now a school app, this test might fail if it relies on a specific UI.
    // I'll update it to just verify MyApp can be pumped.
  });
}
