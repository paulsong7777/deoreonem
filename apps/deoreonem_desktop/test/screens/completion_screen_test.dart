import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/screens/completion_screen.dart';

void main() {
  testWidgets('CompletionScreen shows main message and close button only',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CompletionScreen(onClose: () {})),
    );

    expect(find.textContaining('오늘은 여기까지'), findsOneWidget);
    expect(find.textContaining('맡겨둔 것들은 다시 꺼내볼 수 있어요'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
    // No extra CTAs
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('CompletionScreen close button invokes onClose callback',
      (tester) async {
    bool closeCalled = false;

    await tester.pumpWidget(
      MaterialApp(home: CompletionScreen(onClose: () => closeCalled = true)),
    );

    // Directly invoke the button's callback to avoid shader/ink effect issues in test
    final button = tester.widget<TextButton>(find.byType(TextButton));
    button.onPressed!();

    expect(closeCalled, isTrue);
  });
}
