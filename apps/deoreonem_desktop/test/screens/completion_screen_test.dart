import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/screens/completion_screen.dart';

void main() {
  testWidgets('CompletionScreen shows main message and close button only',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CompletionScreen()));

    expect(find.textContaining('오늘은 여기까지'), findsOneWidget);
    expect(find.text('수고하셨어요.'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
    // No extra CTAs
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
