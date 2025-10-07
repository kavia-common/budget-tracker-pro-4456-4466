import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_frontend/main.dart';

void main() {
  testWidgets('App builds and shows navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // Expect bottom navigation present
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
