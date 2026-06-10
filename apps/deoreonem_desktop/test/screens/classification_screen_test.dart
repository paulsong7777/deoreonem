import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deoreonem_desktop/screens/classification_screen.dart';

void main() {
  testWidgets('ClassificationScreen shows item card and 7 category buttons',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClassificationScreen()));

    // Progress text
    expect(find.textContaining('분류됨'), findsOneWidget);
    // First few category buttons visible
    expect(find.text('지금'), findsOneWidget);
    expect(find.text('내일'), findsOneWidget);
    expect(find.text('이번 주'), findsOneWidget);
    expect(find.text('대기 중'), findsOneWidget);
    expect(find.text('메모'), findsOneWidget);

    // Scroll down to reveal remaining buttons
    await tester.scrollUntilVisible(
      find.text('버리기'),
      50.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    expect(find.text('걱정만'), findsOneWidget);
    expect(find.text('버리기'), findsOneWidget);
    // Item card with mock content
    expect(find.byType(Card), findsWidgets);
  });
}
