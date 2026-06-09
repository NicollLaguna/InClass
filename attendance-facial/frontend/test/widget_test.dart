import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('InClassApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const InClassApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
