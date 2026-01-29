import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arecasafe_main/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ArecaSafeApp());

    // App loads without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
