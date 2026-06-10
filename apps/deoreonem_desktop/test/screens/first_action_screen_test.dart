import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/screens/first_action_screen.dart';

void main() {
  testWidgets('FirstActionScreen shows prompt and item list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FirstActionScreen()));

    expect(find.text('내일 가장 먼저 할 일 하나를 고르세요.'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
    expect(find.byType(Radio<int>), findsWidgets);
  });
}
