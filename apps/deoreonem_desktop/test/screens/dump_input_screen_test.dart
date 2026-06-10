import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/screens/dump_input_screen.dart';

void main() {
  testWidgets('DumpInputScreen has title, text field, and disabled next button',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DumpInputScreen()));

    expect(find.text('오늘 남은 것들'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    // Next button should be disabled when list is empty
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('DumpInputScreen enables next button after adding item',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DumpInputScreen()));

    await tester.enterText(find.byType(TextField), '테스트 항목');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });
}
