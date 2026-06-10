import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/screens/start_screen.dart';

void main() {
  testWidgets('StartScreen displays app name, subtitle, and start button',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartScreen()));

    expect(find.text('덜어냄'), findsOneWidget);
    expect(find.text('오늘 머릿속에 남아있는 것들을 꺼내 보세요.'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('v0.1.0'), findsOneWidget);
  });
}
